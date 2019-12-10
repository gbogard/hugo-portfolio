---
type: Project
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
images:
  - ../../assets/images/projects/pingflow.gif
---

I've worked for a year as a lead developer for this Start-up specialized in _visual management_. My mission was to develop a tool that would help
teams share information faster thanks to big, interactive panels that directly interact with the information system.

This tool, _Pingview_ had to be simple enough to allow anyone to create digital wallbaords and yet powerful enough to display relevent information from various sources, 
including APIs, relational databases, RSS feeds ... Dynamic wallbaords would be created by dragging elements in place, connecting them to the information system, and apply _conditions_
to them so they could be hidden, shown, or change style based on the current informattion. In addition, _Pingview_ includes powerful data transformation pipelines that can help extract
the relevent data from various sources in the system.

[Learn more about Pingview](https://www.pingview.io/en/)

## My responsabilities

- Design a new major version of Pingview that could scale to far more users while adding a sgnificant amount of new features that were
difficult to add to the legacy system
- Lead the development team of 4 people by reviewing code, making architecture decisions and helping my peers improve their coding skills
- Develop a lot of features myself, both on the front-end (Vue.js) and on the back-end (node.js and Scala services)
- Work in close collaboration with a DevOps engineer in order to reach maximum scalability and availability of the application

## What I've learned

This was my first attempt at using Vue, Scala and [Akka](https://akka.io/) in production.
It told me a lot about how to use Akka clusters to build scalable services and how to deploy those Akka clusters. It was also the first time I had different tools in the 
the back-end stack, working together to achieve global performance. The communication between the node.js API and the Scala services was far from perfect.
If I had to to do it again, I'd probably use a message broker such as RabbitMQ or Kafka. I would also use something like [cats](https://typelevel.org/cats/) and emphasize
on functional programming.
