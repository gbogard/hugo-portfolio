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
- The fourth part will showcase the *choregraphy pattern*, which we use a lot throughout the application to implement business logic while retaining our
ability to introduce and remove services as need arises.

The introduction is less technical than the remaining parts. It covers the challenges of migrating a critical system from a higher perspective,
while the rest of this series will dive into some implementation details.

Let's do this!

## Why we are moving away

The media management platform (MAM) is at the cornerstone of our video supply chain: it is used by a thousand users on a daily basis to provide content
to a hundred distribution channels across the globe. Since 2011, in virtue a contract between Canal+ and a software vendor, the role of MAM 
is performed by Edgar, a closed-source, monolithic program built on an long-obsolete foundation.

Our main concern with Edgar today is the impossibility of reshaping it to address new needs:

- we want to handle 4K, HDR assets. Edgar doesn't do that
- we want to configure and restrict content distribution on a per-territory basis, as we expand our operations worldwide. 
Edgar doesn't do that, because Canal+ was mostly operating in France when it was introduced
- we want a multilingual application to support our expansion to new countries
- we want to introduce new features, new distribution channels, new video transcoding workflows, quickly and without breaking what we already have

We can't do any of that because Edgar is a proprietary software, built on a proprietary framework, of which we have little knowledge. 
To add to our difficulty, Edgar is not only proprietary, it relies on a 15 year-old version of Java, which we can't bare to maintain any longer.

Considered we can't maintain Edgar ourselves anymore, adding the new features we need  — such as 4K — would force us into another expensive contract with
Edgar's third-party vendor, whereas leveraging our own software teams, and thus keep control of our vital internal tools, would be profitable in the long run. 

To build the software that will replace Edgar for the decade to come, we took a completely opposite approach:

- We're building in-house to avoid locking ourselves in a 15-year contract with another vendor. We're going *inner source*, applying to our organization the best practices
of open-source software development: public Git repositories, shared libraries, pull requests, open issue tracker, open Wiki. 
- Edgar is a monolith, but we are going micro-services. This approach lets us introduce 
new features as they are needed, and remove then when they are no longer needs (more on that on a moment)

## Replacing Edgar: the main challenges

We know we want to shut down our legacy software eventually, but doing to requires time, effort, and a thoughtful approach. Here are some of the things
we need to consider:

- 850K videos is a lot of data to transfer. Many of our data transfer procedures take hours to complete, and involve many different services. Such
long-running procedures need to be resilient: should a dozen-hour-long process crash in the middle, it would be very wasteful to restart from the very
beginning
- Long-running processes should behave correctly with limited resources and bottlenecks: for instance, it is much faster to store something to a relational
database than to transcode a video file. We must regulate long-running processes so that the fastest steps are not giving the slowest steps more work than
they can handle
- Users are still using the legacy system on a daily basis. We cannot shut Edgar down until we can provide them with a replacement that is at least as good
as Edgar on every aspect. Doing so requires being able to not only implement every feature the legacy software has (sometimes in the form of different
feature with greater capabilities), but also transfer every data from the old system the new one.
  - we need **one-shot data replication** to transfer the entirety of the data to a newly-provisioned database
  - and **real-time data replication** so changes users make in Edgar are reflected in Mediahub immediately
- The domain model between the legacy system and the new system are not exactly the same. We've taken this opportunity to modernize the system, not
only in technical terms, but also in features and user experience. This comes at the cost of transforming the data to make it fit the new vision.
Fortunately, Scala's powerful type system enables us to safely transform data from one model to the other, and easily reject invalid data, as will be showcased
later in this series.

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

We have services that retrieve video assets from Edgar, the old MAM system, add them to Mediahub, we have services that transfer editorial
data — keywords, people, places, dates and whatnot —, and services that download thumbnails from an old location and upload them to the new system.
When designing and implementing these services, we make sure to retain our ability to decommission them in the future.

On top of that, we still need to address the challenges I've mentioned earlier: resiliency of long-running processes and replication, both in real time and
in one go, of large amounts of data. We address these remaining challenges in the way our services communicate with one another: through Kafka topics.

### Kafka topics

### Scala services

## Coming up next: tying everything together

See ya!
