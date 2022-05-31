---
title: Full-stack Javascript developer @Decathlon Maps
employer:
  name: Linkvalue
  link: http://link-value.fr
client:
  name: Decathlon
  link: https://www.decathlon.com
startDate: 2019-01-10
endDate: 2019-05-04
images:
  - ./decathlon-maps-1.png
  - ./decathlon-maps-2.png
  - ./decathlon-maps-3.png
tools:
  - react
  - node
  - javascript
description: |
  I worked a progressive web app (PWA) that let people find places for sport practice.
  I developed several features on the front end (React, Redux and Redux Saga) and on the back end as well (Koa and Postgres).
  
  I implemented a better code delivery process, brought code reviews and end-to-end automatic tests to the project, and introduced my peers to
  functional programming principles that led to better separation of the business logic and greater maintainability of the product.

---

## About Decathlon Maps

Decathlon is the largest sporting goods retailer in the world. In addition to their information system and their online store,
they offer several sport-related applications to their customers. Decathlon Maps is one of these applications.

Decathlon Maps is a Progressive Web App (PWA) that you can think of as a specialized Google Maps for sports of all kinds. 
The idea is to reference as many sport places as possible, including sport-specific data e.g. distance and elevation for
running tracks. Users can not only search for sport places but import their own from third-party apps or GPX files.

The application aims at providing a native-like experience for mobile users. The application had us face many technical
challenges, including making the Map as smooth as possible on mobile devices despite the very large number of displayed sport places,
scrapping data from several websites that didn't have any API, and working with geo-location data from different sources that
don't share the same conventions.

## My contribution

- I did my best to improve the overall quality of the existing code bases through automatic testing, a more consistent coding style,
and the introduction of new programming techniques. Specifically:
    - I introduced end-to-end automatic testing of the application (using Cypress)
    - I added unit tests to th existing code base and encouraged my coworkers to thoroughly test any new feature
    - I pushed for the adoption of a proper code delivery workflow that relied on merge requests, in place of the former *push to master* approach
    - I refactored the codebase and shrunk its overall size by 30%
    - I introduced linters and pre-commit hooks to enforce a common code style throughout the team

- I developed several features, both on the back-end side (node.js, Koa and Postgres) and the front-end side (React, Redux
and Redux Saga)

- I taught a few functional programming principles (referential transparency and composition) to my coworkers and introduced Redux Saga. 
I encouraged a strict separation of business logic from side effects, that in turn led to a better testability of the codebase and easier maintenance overall