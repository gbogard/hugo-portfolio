---
title: "Attending NE Scala 2020, my first online-only conference"
date: 2020-03-19
categories:
  - scala
tags:
  - scala
  - conference
  - covid
---

Last week I had the opportunity to attend and speak at [Northeast Scala Symposium](https://nescala.io/), 
this is the story of my experience.

The symposium has been gathering Scala enthusiasts for ten years now, 
and while most of the attendees come from the east-coast of the U.S., it’s usual for European folks to join as well.
It's really three different conferences on three successive days. The first day of talks is the [Typelevel Summit](https://typelevel.org/event/2020-03-summit-nyc/), followed
by the proper NE Scala lineup, and a day of *unconference*. My talk was part of the first day. If you’re not familiar with the
Scala ecosystem, [Typelevel](https://typelevel.org/) is an organization of volunteers that develop open-source libraries geared
toward functional programming. They have set a goal of promoting functional programming through not only
through code, but also through great learning material; and they are committed to building a welcoming, inclusive community. 
The most popular Typelevel project is *Cats*, a library for functional programming that is also one of the best documented pieces
of software I know.

Since I live in France, I was planning to take the plane to attend the conference, and was looking forward to seeing New York City for the first time. But in the face of a major health crisis, things didn’t quite go as planned. 
Two days before the event, [the first COVID-19 cluster near New York was discovered](https://www.nytimes.com/2020/03/12/nyregion/coronavirus-new-rochelle-containment.html?searchResultPosition=2). More and more people were encouraged to stay
at home, and a week later, at this time of writing, France was about to go into quarantine.

Still, instead of canceling the event altogether, the organizers of the symposium decided to organize an online-only event, 
and the entire lineup of talks was maintained. I may not have seen New York, but it was still a very successful event.

## Submitting the talk and preparing

It was through the [@typelevel](https://twitter.com/typelevel) Twitter account that I first heard of the call for paper for the
Typelevel Summit, and I decided to submit a talk on a whim thinking, "We'll see how this goes.” In the middle of December, my
submission was on Papercall. It was a talk I had already given in French earlier, about IO monads and error management. 
It was essentially an introduction to Cats MTL, another library of the Typelevel ecosystem, and it fitted the conference well.
Now that it was submitted, all I could do was wait for a response from the organizers.

In the meantime, my employer [Linkvalue](https://link-value.fr/fr), a software consultancy company, held a 2-day training
session about public speaking. With the help of [Tim Carry](https://twitter.com/pixelastic), an experienced developer and a mentor
in public speaking for tech events, my colleagues and I practiced our presentation skills. We did many recorded exercises,
and even gathered ideas for future talks, but that's a story for another time.

With all the insight from the training session and my former experience as a speaker, I thought I was sort-of ready, just in
case the organizers decided to go along with my talk.

A couple of months go by, and in February, while taking by breakfast, I get an e-mail through Papercall telling me
my talk was accepted. What had been an abstract idea so far was about to get very real.
In a matter of weeks, I needed to book a plane, an accommodation,  open a bank account to avoid banking fees 
abroad and, of course, get ready to speak. I had the first three done by the end of the day. 
All that was left for me to do was to finish preparing for the big day.

I already had a slide deck for the talk but finally decided that I wasn’t quite happy about how it looked. 
Most importantly, I had never given a talk in English before, and I felt a bit rusty. In the two weeks that predate the event,
I recorded myself while rehearsing the talk, and remade all the slides using *Deckset*, a tool to make presentations using Markdown.
The most important part of this new slide deck is the added GIFs as transitions, because a deck never has too much GIFs, right?

![Creating the slides in Deckset](./deckset.gif)

Eventually I decided that my slides looked fine and that my pronunciation was good enough. i had all the details of my trip sorted.
All was left to do was wait for the big event, go on with my daily life, and try not to worry too much.

## Safety first

In the days just before the symposium, the number of confirmed COVID-19 in western Europe was growing at an alarming rate.
At first, most people, me included, were thinking, "This is fine, it's just a bad flu.” But at some point we all had to admit that
the situation was worse than we thought.

I was beginning to feel concerns about taking the train, then going to the airport, being exposed to big crowds
that could transmit the virus to me, and in turn risking transmitting it to other people too. On March 9th, the day before
my flight to New York, the number of confirmed cases in France reached 1412, hundreds more than the day just before.
Attending the conference was starting to look irresponsible.

My day of work passed as usual, but once I got home in the evening, I expressed my concerns to my significant other, called
my parents for more advice, and eventually decided not to go. The hard part of making this kind of decision is that 
it's hard to assess the real risks. At that time, the coronavirus epidemic was starting to get scary, but not nearly as
scary as it is now, two weeks later. The temptation to go see New York despites all risks was high, and canceling my trip
first fell like a sacrifice. But in regard of how things turned out, I am confident that this was the right decision.

And the organizers thoughts too. Moments after deciding that I would not take the plane, as I was contacting a Typelevel
member on Twitter, I saw that the NE Scala team was inquiring everyone to stay at home. But instead of completely
canceling the event, they decided to make it online only, and managed to pull it off in just a couple of days. The entire 
lineup of talks was maintained.

## Attending the online event

The conference organizers used a combination of Slack and Zoom to make the online event happen, and it went way
better than I feared it might. I will not go over too many details on how the conference actually worked, because
the conference chairman, Ryan Williams, posted [a detailed debrief](https://gist.github.com/ryan-williams/4e2f21fa1d3493674ac52c766a02e637) on GitHub. It covers pretty much everything, from they had to cancel almost everything
last minute, to how they managed to build an atmosphere of conviviality despite people being split across the globe.

However, here are a few things that I particularly liked during the event: 

- Various conference rooms to hang out between the talks, somewhat replacing the kinds of social interactions
people love about physical conferences
- A great lineup of talks. I had several *aha!* moments during the conference, thought of many things that could
help me in my day job, especially talks that would help me introduce functional programming concepts to my coworkers better
than I would have. I was also pleasantly surprised to see talks focusing less on the technical aspects of programming, and
more on the social aspects. There were talks on how to build a more inclusive team, overcome our prejudices, teach Scala
to people of diverse backgrounds and even, very much to the point, how to build a remote team. Overall, the conference sets
up a goal of building a more inclusive community for Scala developers, and the lineup reflected that goal well.
- Overall kindness and consideration of all the attendees. All of the people I interacted with have been friendly and
respectful, and made for an even better experience.

Some people even felt that this remote conference had unexpected benefits: a more relaxed atmosphere, the ability to watch 
talks while being comfortably seated (not to be neglected when watching talks for three straight days), and the possibility 
for a wider audience to attend. Making this an online event enabled people to come who wouldn't have been able to travel
otherwise.

As for my experience as a speaker, everything went well overall, and I was pleasantly surprised by the number of questions and
interest that my talk generated. My video was a bit choppy at times, but I assume it's because I was speaking from across the
ocean. The only real downside for me has been the time difference. Speaking at 10p.m. after a full day of watching talks
is a bit rough and I felt somewhat out-of-sync with most of the other participants.

## Next steps

Attending NE Scala this year has been a wild experience. Lots of first times for me: first time giving a talk
in a foreign language, first time attending an online conference, first time meeting some well-known members of
open-source Scala community (people have all been very cool). Also, a few days later, first time living in quarantine.

I have to thank again all the people that made it possible, starting with Ryan Williams and all the organizers of the event.
Going online only in these uncertain times was the best decision. The incredible success of the conference has even inspired
people to organize more online events, like the soon to be [Scala Love online conference](https://www.papercall.io/scalalove).

I'd also like to thank the people that helped me prepare and refine my talk to make it the best possible: the
[Lambda Lille meetup](https://www.meetup.com/fr-FR/LambdaLille/) for hosting my first enactment of the talk,
[Linkvalue](https://link-value.fr) for giving me the opportunity to improve my public skills and giving the ability
to leave to attend conferences. Finally, I am grateful to my s.o. for encouraging me into working on the talk when I
didn't have the energy.

All the videos from the conference should be online soon, and I plan on writing a blog post on functional error management,
covering everything that my talk covered and even going further. In the meantime, take care, stay home and curry-on.