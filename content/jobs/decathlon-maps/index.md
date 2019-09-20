---
title: Decathlon Maps
employer:
  name: Linkvalue
  link: http://link-value.fr
client:
  name: Decathlon
  link: https://www.decathlon.com
startDate: 2019-01-10
endDate: 2019-05-04
images:
  - ../../assets/images/projects/decathlon-maps-1.png
  - ../../assets/images/projects/decathlon-maps-2.png
  - ../../assets/images/projects/decathlon-maps-3.png
tools:
  - react
  - node
  - javascript
---

Decathlon Maps is a Progressive Web App (PWA) that acts like a Google Maps for sports of all kinds. The idea
is to reference as many sport places as possible, including sport-specific data e.g. distance and elevation for
running tracks. Users can not only search for sport places but import their own from third-party apps or GPX files.
The application aims at providing a native-like experience for mobile users. The application had us face many technical
challenges, including making the Map as smooth as possibl on mobile devices despite the large number of displayed sport places,
scrapping data from several websites that didn't have any API, and working with geolcation data from different sources that
don't share the same conventions.

I joined the project in January as a backup before the first production deployment. I had the chance to refactor the
existing code, implement better code practices, and train the existing teams to functional programming principles and
idiomatic React / Redux / Redux Saga patterns.

## What I've brought

- I developped several features, both on the back-end side (node.js, Koa and Postgres) and the front-end side (React, Redux
and Redux Saga)
- I initiated a refacoring process that reduced the size of the code base by 20% (in lines of code) while improving the
performance of the existing features
- I teached functional programming principles to the existing team and helped them achieve *DRY*er code and better state
management
- I tried to establish better code practices :
  - Writing comprehensive development guidelines that include tips on functional programming, idiomatic React,
  database model management ...
  - Establishing peer-reviewed pull requests instead of the former *push to master* approach
  - Adding unit tests and end-to-end tests to prevent regression while trying to code in a more user-centric, or
  feature-centric manner
  - Establishing linter rules and pre-commit hooks to enforce a common code style throughout the team
  
The project was about a year old when I joined the team. It had most of the features developped but lacked the
development practices that would allow one to develop and deploy with confidence. Overall, my mission was mainly 
to bring as many good practices as I could, help the team gain new skills, and also develop a few features before the
first release.
