---
type: Post
title: "Domain-driven design meets functional programming: a reasonable approach to software development"
date: 2020-02-19
tags:
 - scala
 - software craftsmanship
 - ddd
---

## Foreword

Today I'm starting a series of many blog posts with the goal of presenting what I have learned about domain-driven design applied to functional programs over the last few years. I am convinced that functional programming, especially in statically typed languages, is the best way of delivering programs that start *correct* and stay correct over time. Functional programming allows us reason about *abstraction*, *side-effects* and *composition*. It allows us to solve big problems out of smaller ones, and teaches us when to abstract, and what to abstract over. I have been using functional programming on real-world applications with great success and have invested much of my time teaching it through meetups, training sessions and blog posts like this one.

However, it is also my conviction that functional programming alone is not enough to deliver software fitted for the enterprise. Functional programming is a technical approach, like other paradigms and design patterns. In order to deliver quality software, one must not only think in the terms of a technician, but also immerse themselves in the business domain of their program and understand the value their software need to deliver.

Perhaps ironically, software developers are hardly ever judged by the quality of their code but by the value their software produces for the business holders, or, to put it in other terms, the job of a developer is not to write code for the sake of it but to solve problems. Of course there are exceptions to this, in the academic field or if your business itself is closely related to software, this is why in this blog posts series, I'll talk mostly about *enterprise software*. Think of the typical big Java app that is so critical for the business yet so hard to maintain no one fully understands it.

The issues I'll attempt to cover have been known for a long time now, yet they remain very present in the industry and continue to cause lots of frustration for engineers and business owners alike. This my take on how to *fix* enterprise software development. I believe that traditional object-oriented software is doomed to poor scaling and high maintenance costs due to the way they encourage mutable states, side-effects of all sorts and sub-typing, but FP on its own is no silver bullet either. This is why I'll attempt to demonstrate what the combination of an expressive language like Scala, functional programming principles and meticulous attention to the domain can do to improve the daily lives of developers and the robustness of business-critical software.

## Table of contents

So far, this is how I intend to structure this series, although this may still change :

- What is domain-driven design, and why should you care?
- Different ways to understand functional programming
- Applying the hexagonal architecture in Scala : putting domain back at the heart of software
- Modeling a rich domain using types
- Reasoning with effects and making your code easier to test
- Testing your code : what to test and how

Keep in mind that, While pursuing the goal of being as informative as possible, these posts also include a their fair share of opinions, which are subject to debate, and perhaps mistakes, which I'm willing to correct. We're all perpetual learners after all.

Feel free to address me your feedback on [Twitter](https://twitter.com/bogardguillaume) or by [e-mail](mailto:hey@guillaumebogard.dev).