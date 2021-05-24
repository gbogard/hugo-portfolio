---
type: Post
title: Moving away from a legacy system using Scala and Kafka - Part 1
subtitle: The challenges of migrating our media assets management system
date: "2021-05-18"
tags:
  - scala
  - cats
  - fp
---

My team at [Canal+](https://www.canalplus.com/) is building a new media asset management (MAM) platform. To put it simply, Mediahub, our platform,
stores video files and all kinds of information regarding these files: 

- technical information (*how many audio channels does this video have?
what's the video's resolution?*)
- editorial information (*is it a movie? a show? a TV series episode? who is speaking in the sequence? what about?*)
- and legal information
(*when can we air this content?*, *when did we acquire this contract?*)

On top of storing and exposing tools to manipulate video files and their related metadata, the platform allows third-parties
to send us new video elements, and users to ship these elements to VOD platforms and TV channels outside Mediahub, meaning the number of video assets we're managing
is ever-growing.

![The MAM stores media assets and their related metadata, and delivers them to third-party platforms, such as myCANAL or TV Channels](../illustrations/mam.png)

The Mediahub project is born roughly in 2017, but Canal+ has been a leader of pay-television, film production and film distribution in France for decades, meaning a vast
proportion of the video footage we manage comes from a legacy system. Out of roughly 1M medias we are managing, 900K come from the old system; a system we are trying to
slowly replace, using Kafka, Scala, and functional programming as our main tools.

In this series of articles, I will explain why we are moving away from that legacy system and how we are doing it. 
I'll go from a big picture of our architecture (ETL pipelines built on Kafka) to some neat implementation details 
(using Cats to validate and transform loosely-structured data), in an attempt to showcase how Kafka, Scala and functional programming allow us to modernize our internal
video management tools.

- The introduction, this article, will provide some background regarding our product and our transition to a better system; it will also introduce
the building blocks of our transition: Kafka topics and functional microservices written in Scala.
- The second part will cover our data migration pipelines in more detail.
- The third part will cover our functional services, and showcase how Scala's type system and neat programming concepts like algebraic data types and functors
(they're not as scary as they sound!) help us transform and validate data safely and easily.
- The fourth part will showcase the *choreography pattern*, which we use a lot throughout the application to implement business logic while retaining our
ability to introduce and remove services as need arises.

The introduction is less technical than the remaining parts. It covers the challenges of migrating a critical system from a higher perspective,
while the rest of this series will dive into some implementation details.

Let's do this!

## Why we are moving away

The media management platform (MAM) is at the cornerstone of our video supply chain: it is used by a thousand users on a daily basis to provide content
to a hundred distribution channels across the globe. Since 2011, in virtue a contract between Canal+ and a software vendor, the role of MAM 
is performed by Edgar, a closed-source, monolithic program built on an long-obsolete foundation.

Our main concern with Edgar today is the impossibility of reshaping it to address new needs:

- It's 2021. People want 4K and HDR videos. Edgar doesn't handle them.
- We want to configure and restrict content distribution on a per-territory basis, as we expand our operations worldwide. 
Edgar doesn't do that, because Canal+ was mostly operating in France when it was introduced
- We want a multilingual application to support our expansion to new countries
- We want to introduce new features, new distribution channels, new video transcoding workflows, quickly and without breaking what we already have

At best, adding these changes to Edgar would require another expensive contract with a third-party vendor. And that is if they're possible at all.
Rather than throwing money to maintain a 15 year-old piece of software, we've decided implement ourselves our MAM for the decade to come.

- We're building in-house to avoid locking ourselves in a 15-year contract with another vendor. We're going *inner source*, applying to our organization the best practices
of open-source software development: public Git repositories, shared libraries, pull requests, open issue tracker, open Wiki. 
- We're breaking free from the monolith and going full micro-services. This approach lets us introduce 
new features as they are needed, and remove then when they are no longer needs (more on that on a moment)

## Replacing Edgar: the main challenges

Replacing such critical software requires time, effort, and a thoughtful approach. Here are some of the things we need to consider:

- 850K videos is a lot of data to transfer. Many of our procedures take hours to complete, and involve many different services. 
Should a dozen-hour-long process crash in the middle, it would be very wasteful to restart from the very beginning
- Long-running processes should behave correctly with limited resources and bottlenecks: for instance, it is much faster to store something to a relational
database than to transcode a video file. We must regulate long-running processes so that the fastest steps are not giving the slowest steps more work than
they can handle
- Users are still using the legacy system on a daily basis. We cannot shut Edgar down until we can provide them with a replacement that is at least as good
as Edgar on every aspect. Doing so requires being able to not only implement every feature the legacy software has (sometimes in the form of different
feature with greater capabilities), but also transfer every data from the old system the new one.
  - we need **one-shot data replication** to transfer the entirety of the data to a newly-provisioned database
  - and **real-time data replication** so changes users make in Edgar are reflected in Mediahub immediately
- We don't want to make a mere copy of Edgar on a more recent foundation, we want to build a radically better system. As we reimagine our video supply chain, and 
change the underlying data model, data from the legacy will need to be *translated* to the new model. Fortunately, Scala's powerful type system allows us to express these
transformations safely, and easily reject invalid data.

## The building blocks of our architecture: Scala microservices and Kafka topics

<img style="max-height: 300px; margin-right: 2rem" align="left" src="../illustrations/kafka-scala.png">

While Edgar was a Java monolith, we've taken the opposite approach and built Mediahub as a distributed system, made up of 120+ micro-services, 
the vast majority of which implemented in Scala.

While distributed systems are notoriously harder to implement and maintain (notably regarding data consistency and 
[infrastructure](https://microservices.io/articles/deployment.html]), this approach as allowed us to handle some of the 
hardest challenges of migrating a critical system.

In particular, this architecture allows to segregate *legacy-specific services* and *data adapters* from broader and more durable services.
Indeed, Mediahub is a connected system: connected to the legacy software, whose data needs to be replicated in real time as long as it is running;
and connected to external systems (third-party APIs, subsidiaries of the Canal+ group etc.) with which we need to interact. 
Interacting with these services requires specific code, and the microservices architecture lets us separate that code from the rest of the system.
Of course, even a monolith should clearly separate concerns, this isn't something you can't achieve without microservices;
but there's one question that a modular architecture answers very well: "What if I don't need that anymore?"

**We've found that being able to decommission parts of the application is just as important as adding parts to address new needs.** 
Delivering to our users a smooth transition from the old system to the new one is crucial to our business; and the best way to achieve 
it is to have loosely-coupled services that can take out of from the system at any time, with little or no interruption of service.

### Inter-service communication

Dividing the application into microservices forces us to be more conscientious about separation of concerns. We strive to keep a service's boundaries small, and
its knowledge of the outside world limited. We ensure that services don't know about one another, and thus don't call one another directly, unless absolutely necessary.

A service whose only goal is to manipulate data from the legacy may depend on a permanent, broader service, but never the other way around, as our ability to decommission legacy-specific
services lies in the fact that no other service depends on them.

While especially crucial for this whole legacy transition, this principle also applies to more permanent parts of the system. It isn't uncommon for a service to apply business rules
in reaction to an event in another service. In this scenario, the service that provoked the event emits a message in a Kafka topic. The message will be consumed by other services without
the original producer's knowledge. When a chain of services emits and consumes events that way to produce a distributed transaction, we call it a choreography, but will discuss it later.

Kafka topics are essentially partitioned and ordered collection of events that have multiple producers and multiple consumers within a system. 
They are not only useful for propagating events across loosely-coupled services; they enable us to build large ETL (*extract, transform, load*) pipelines, to move massive amounts
of data from the old system to its successor. Kafka is a distributed streaming platform. 
Streams let us reason about data emitted over time: they give us a declarative and composable way of handling massive — possibly infinite — amounts of data, 
which are modeled as successive and bounded sequences of elements called chunks. In a [video about a year ago](https://www.youtube.com/watch?v=YWhrrfP3718), I've shown
how [fs2](https://fs2.io/#/), a popular streaming library for Scala, could easily be used to transform a CSV file of several gigabytes using limited memory. Despite being very powerful,
fs2 itself can model data flowing within a single JVM, and not across services; but Kafka lets us apply what we know and love about streaming to build pipelines that spans multiple
services, and still retain the same essential properties:

- when order matters, Kafka can ensure that consumers receive events in the order they were produced. When it doesn't, Kafka lets multiple consumers process events concurrently 
to achieve higher throughput. If some services care about the order of events and some don't, 
[it lets us get that best of both worlds by organising consumers into groups](https://codeburst.io/combining-strict-order-with-massive-parallelism-using-kafka-83dc1ec9be03)


### Scala services

## Coming up next: tying everything together

See ya!
