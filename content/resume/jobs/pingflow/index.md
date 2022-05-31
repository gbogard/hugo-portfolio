---
title: Full-Stack developer @Pingflow
employer:
  name: Pingflow
  link: https://www.pingflow.com/en/home/
lead: true
startDate: 2016-11-01
endDate: 2017-12-15
tools:
  - vue
  - node
  - scala
  - javascript
  - kubernetes
images:
  - ./pingflow.gif
description: |
  Pingflow develops a no-code software a service that allows anyone
  to design big, interactive dashboards that automatically displays up-to-date information from various data sources. These dashboards can be created
  by dragging elements on a canvas, and connecting them to data sources such as APIs, SQL databases and spreadsheets. 

  I led the development of a new major version of the product and migrated the codebase to a more modern an more scalable architecture: from stateful services
  that were hard to scale to stateless services that could scale horizontally, from jQuery to Vue, from Javascript to Typescript, from release in zip files to containers.

  It was also my first professional experience with Scala and Akka, which I has taught myself and introduced in an attempt to build a more
  scalable platform. Actors and message-passing made it easier to reason about the live data update that were dispatched throughout the system.
---

## About Pingflow

Pingflow is a startup that specialized in *visual management*. Their main product is a no-code software as a service (SaaS) that allows anyone
to design big, interactive dashboards that automatically displays up-to-date information from various data sources. These dashboards can be created
simply by dragging customizable elements on a canvas, and connecting them to data sources such as APIs, SQL databases and spreadsheets.

In addition, the software includes powerful data transformation pipelines that can help extract and sanitize
the relevant data coming from various sources.

[Learn more about Pingflow](https://www.pingview.io/en/)

## My contribution

- I lead a small team of developers and participated in the recruitment process. I made architecture decisions and encouraged code reviews.
- Our product, Pingview, was having difficulties handling the load and was impossible to scale horizontally. 
  I led the development of a new major version of Pingview that could handle far more users thanks to a stateless architecture, and added 
  a significant amount of new features that were difficult to add to the legacy system
- I migrated the back end from dynamically-typed, vanilla Javascript to Typescript
- I migrated the front end from server-side HTML and jQuery to Vue.js
- I introduced Redis as a cache layer for our data, and as a pub/sub system for live data updates. This contributed to reduce the response times of the 
  application, and allowed the platform to handle thousands of data updates per second.
- I brought Scala and more specifically Akka to the back-end stack, thinking it would help us achieve faster data updates and easier horizontal scalability.
  Actors and message-passing made it easier to reason about the live data update that were dispatched throughout the system.
  
  It was my first experience with Scala in production, and surely there are many things that I would do differently. I had no knowledge of the Typelevel ecosystem at the time,
  and very little knowledge of the JVM; but this new version of Pingview was a success overall and it encouraged me to pursue learning Scala.
- I worked in close collaboration with a DevOps engineer in order to reach maximum scalability and availability of the application. We distributed
  the application as a set of Docker images, and deployed it on a Rancher cluster
