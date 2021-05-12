---
type: Post
title: Moving away from a legacy system using Scala, Cats and Kafka - Part 1
date: 2021-05-02
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

The Mediahub project is born roughly in 2017, but Canal+ has been a leader of pay-television, film production and film distribution in France for decades, meaning a vast
proportion of the video footage we manage comes from a legacy system. Out of roughly 1M medias we are managing, 900K come from the old system; a system we are trying to
slowly replace, using Kafka, Scala, and functional programming as our main tools.

In this series of articles, I will explain why we are moving away from that legacy system and how we are doing it. 
I'll go from a big picture of our architecture (ETL pipelines built on Kafka) to some neat implementation details 
(using Cats to validate and transform loosely-structured data), in an attempt to showcase how Kafka, Scala and functional programming allow us to modernize our internal
video management tools.

## Why we are moving away

The media management platform (MAM) is at the cornerstone of our video supply chain: it is used by a thousand users on a daily basis to provide content
to a hundred distribution channels across the globe. Since 2011, in virtue a contract between Canal+ and a software vendor, this role 
is performed by Edgar, a closed-source, monolithic program built on an long-obsolete foundation.

Our main concern with Edgar today is the impossibility of reshaping it to address new needs:

- we want to handle 4K, HDR assets. Edgar doesn't do that
- we want to configure and restrict content distribution on a per-territory basis, as we expand our operations worldwide. 
Edgar doesn't do that, because Canal+ was mostly operating in France when it was introduced
- we want a multilingual application to support our expansion to new countries
- we want to introduce new features, new distribution channels, new video transcoding workflows, quickly and without breaking what we already have

We can't do that because Edgar is a proprietary software, built on a proprietary framework (WebSphere), of which we have very little knowledge. To add to our
difficulty, Edgar is not only proprietary, it relies on a 15 year-old version of Java, which we can't bare to maintain any longer.

To tackle these issues, we took a completely opposite approach:

- We're building in-house to avoid locking ourselves in a 15-year contract with another vendor. We're going *inner source*, applying to our organization the best practices
of open-source software development: public Git repositories, shared libraries, pull requests, open issue tracker, open Wiki. 
- Edgar is a monolith, but we are going micro-services. 
