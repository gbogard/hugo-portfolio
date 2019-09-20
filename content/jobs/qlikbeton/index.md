---
type: Project
title: Qlikbeton
employer:
  name: Linkvalue
  link: http://link-value.fr
client:
  name: Qlikbeton
  link: https://qlikbeton.be
startDate: 2018-01-01
endDate: 2018-06-15
images:
  - ../../assets/images/projects/qlikbeton-1.gif
  - ../../assets/images/projects/qlikbeton-2.png
tools:
  - react
  - javascript
---

Qlikbeton is an online marketplace that sells concrete at attractive prices during off-peak periods. They're selling in
four different countries, each with custom business rules and different styling. My job was to develop the front-end part
of the website within a team of 4 front-end developers.

We had to figure out ways to address all target countries while avoiding code duplication as much as possible. We came
out with a configuration system that could override not only style but complete part of the application based on the
country.

The project was developed using the best practices of React and Redux, including proper handling of side effects in Redux
Saga, TDD with 100% test coverage and a much as pure code as possible. We used ramda extensively and followed functional
programming principles that allowed us the keep a small and sane codebase.

## What I've learned

It was my first time using [Ramda](https://ramdajs.com/) in a project. It made it much easier to compose and reuse 
our pure functions. 

I had the chance to work closely with another functional programming enthisiast. Exchanging our views allowed me
to be even more confortable in the practice of functional programming.
