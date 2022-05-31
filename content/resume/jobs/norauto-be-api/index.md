---
title: Front-end developer @Norauto
employer:
  name: Linkvalue
  link: http://link-value.fr
client:
  name: Norauto
  link: https://www.norauto.fr/
startDate: 2018-06-15
endDate: 2019-01-10
tools:
  - react
  - vue
  - polymer
  - javascript
description: |
  I developed progressive web apps (PWA) as part of a complete overhaul of Norauto's information system.

  As a team, we built a library-agnostic design system using custom web components (developed using Polymer) and leveraged
  those components in several PWAs, implemented using Vue and React.
---

## About Norauto

Norauto is the largest car parts, car accessories and car repairs dealer in France, and also a major player
in Spain, Italy, and several other countries. In 2018, they undertook a complete overhaul of their information system:
everything from customer management, to loyalty programs, to car parts registry. Several feature teams were developing micro-services using
Go, node.js and Scala, and my team was developing user interfaces using Vue and React. 

## Working environment

We were a small team that strived for excellent code quality. Our entire code base was covered by unit tests and automatic end-to-end tests, and
every change to the code base had to be approved by two people. We reviewed one another's code in mob review sessions, and regularly took part in
*dojos*, group coding sessions for the sole purpose of improving our skills.

This was was our overall approach of front-end development:
- we leveraged [custom elements](https://html.spec.whatwg.org/multipage/custom-elements.html#custom-elements) to build a library-agnostic design system
that could deliver high quality user experiences without compromising on consistency, reducing brand recognition or locking ourselves in a framework
- we documented this design system and made it available to everyone in the company, thus encouraging front-end engineers outside our team to build
on a common infrastructure
- we embraced the *micro frontend* philosophy: each subset of the overall domain (each *bounded context* in the domain-driven design lingo) was treated
as an effectively independent application. This improved the maintainability of individual applications and forced us to strictly separate concerns and carefully
consider every external interaction

## My contribution

- I helped members of the team acquire new skills, especially React since I was the most comfortable with React among my coworkers:
    - I introduced the syled-components library
    - I encouraged the use of React 16 Context API, which was new at the time
    - I trained my coworkers to state management practices (dumb vs smart components, centralized data store...)
- I was very proactive in the writing of new user stories and the design of interfaces mockups, doing my best to
suggest the best user experience possible based on my previous experience building and using applications

