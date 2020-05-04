---
type: Post
title: Functional error handling with monads and monad transformers
date: 2020-05-01
tags:
 - scala
 - cats
 - fp
---

The way we deal with failure in most OOP applications is itself a common source of unexpected behaviors.
I believe Exceptions and `try/catch` statements are overused. Most of the times, it isn't obvious what a method might 
throw and when. Edge causes should be treated with the same amount of caution, if not more, than the rest of the code, yet they are rendered
invisible by error-handling mechanisms that hide failures instead of highlighting them.

In this blog post, I will showcase some functional programming techniques, namely monads, monad transformers and Cats MTL, that can
help you deal with failure, in a way that makes it clearly visible. I will also cover the separation of technical failure and business edge-cases
to keep business logic where it belongs: at the heart of your software. Prior knowledge of the aforementioned concepts is not required,
as I will attempt to define them along the way. Be aware though that these definitions neither exhaustive
nor the most rigorous. There are as many ways of explaining monads as they have use cases, error handling is just one of them. For a broader definition of
monads, I recommend [this article by Mateusz Kubuszok](https://kubuszok.com/2018/different-ways-to-understand-a-monad/#monad).

## The issues with exceptions

It is common practice, in object-oriented programming, to deal with errors using Exceptions and `try/catch` statements. The way they work is familiar to most
developers: something goes wrong, you `throw` an object that represents the issue, and the object will propagate across the entire call stack,
until either a `catch` block is met, or the application shuts down.

This mechanism is convenient and has made is easy to implement
common error handling strategies:

- the way methods can choose to either `catch` an exception or escalate it forms a *chain of delegation*, in which supervising methods are
responsible for the errors of their subordinates. In a way, exceptions mimic the behavior of hierarchies we can find all around us. Like many
OOP concepts, they first seem easier to understand by comparison with the real world
- the fact that an uncaught exception will eventually shutdown the application means it's easy to implement fatal exceptions: just let them run free.
This is surely way more convenient that explicitly calling `exit` when you need to. Right?

But this convenience does not compensate for the risks and mental overhead exceptions produce. When overused, exceptions introduce complexity and potential bugs
to the code base, which all come from this single flaw: exceptions are invisible.

When you look at the signature of a method, you cannot know for certain whether it can fail and under which circumstances. Annotating the method with a 
comment that says "be careful, this might throw these exceptions" is considered a best practice in many languages, and some have a conventional way of doing it,
like `@throws` in Java. But we've all witnessed methods that would throw in production without any prior notice, or annotations that would straight lie to our face.
After all, the compiler doest not compel me into telling the truth in comments, only proper code review does. People run out of time, get neglectful, forget comments here
and there, and there you have it: uncaught exception in production.

Often, business logic gets added as the software evolves, not everyone is properly informed, obsolete documentation is left behind.

```scala
/**
* This never throws, trust me.
*/
def computeDiscountedPrice(originalPrice: Float, discountPercent: Float) = {
  if (discountPercent > 75) {
    // If you're going to document errors poorly, 
    // you might as well make sure your messages are cryptic and unhelpful
    throw new RuntimeException("Can't apply discount")
  } else {
    originalPrice - (originalPrice * discountPercent / 100)
  }
}
```

In fact, the only way to know for sure the circumstances under which a method may throw is to inspect its implementation and the implementation of
all the methods therein recursively. I hope you can get a feel of the ridiculous mental overhead this introduces, particularly in large code bases. 
When I'm implementing a feature, I should be able to understand the existing  code by looking at, and trust what I'm looking at. 
I should be able to do that without fear of unknown edge-cases and unadvertised side effects sneaking behind my back.

This, for me, is one of the main reasons why functional programming is so compelling. FP is, among other things, about trusting what you see. The frustration
caused by traditional error handling patterns alone is enough to motivate the learning of something else entirely.

So, if not exceptions, what then?

## Monads, a short definition

## IO monads, why do we care?

## Error handling using Cats Effect's IO

## Domain edge cases vs technical failures. Don't mix them up!

## The difficulty of combining effects

## A short detour : tagless final

## Examples and conclusion