---
type: Post
title: "Scala: Functional and asynchronous error handling with monads and monad transformers"
date: 2020-05-01
tags:
 - scala
 - cats
 - fp
---

The way we deal with failure in most OOP applications is itself a common source of unexpected behaviors.
I believe exceptions and `try/catch` statements are overused. Most of the time, it isn't obvious what a method might 
throw and when. Edge causes should be treated with the same amount of caution, if not more, than the rest of the code, yet they are rendered
invisible by error-handling mechanisms that hide failures instead of highlighting them.

In this blog post, I will showcase some functional programming techniques, namely monads, monad transformers and Cats MTL, that can
help you deal with failure, in a way that makes it clearly visible. I will also cover the separation of technical failure and business edge cases
to keep business logic where it belongs: at the heart of your software. Prior knowledge of the aforementioned concepts is not required,
as I will attempt to define them along the way. Be aware though that these definitions neither exhaustive
nor the most rigorous. There are as many ways of explaining monads as they have use cases, error handling is just one of them. For a broader definition of
monads, I recommend [this article by Mateusz Kubuszok](https://kubuszok.com/2018/different-ways-to-understand-a-monad/#monad).

## The issues with exceptions

It is common practice, in object-oriented programming, to deal with errors using exceptions and `try/catch` statements. The way they work is familiar to most
developers: something goes wrong, you `throw` an object that represents the issue, and the object will propagate across the entire call stack,
until either a `catch` block is met, or the application shuts down.

This mechanism is convenient and has made is easy to implement
common error handling strategies:

- The way methods can choose to either `catch` an exception or escalate it forms a *chain of delegation*, in which supervising methods are
responsible for the errors of their subordinates. In a way, exceptions mimic the behavior of hierarchies we can find all around us. Like many
OOP concepts, they first seem easier to understand by comparison with the real world.
- The fact that an uncaught exception will eventually shut down the application means it's easy to implement fatal exceptions: just let them run free.
This is surely way more convenient that explicitly calling `exit` when you need to. Right?

But this convenience does not compensate for the risks and mental overhead exceptions produce. When overused, exceptions introduce complexity and potential bugs
to the code base, which all come from this single flaw: exceptions are invisible.

When you look at the signature of a method, you cannot know for certain whether it can fail and under which circumstances. Annotating the method with a 
comment that says "be careful, this might throw these exceptions" is considered a best practice in many languages, and some have a conventional way of doing it,
like `@throws` in Java. But we've all witnessed methods that would throw in production without any prior notice, or with annotations that would lie to our face.
After all, the compiler does not compel me into telling the truth in comments, only proper code review does. People run out of time, get neglectful, forget comments here
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
I should be able to do that without fear of unknown edge cases and unadvertised side effects sneaking behind my back.

This, for me, is one of the main reasons why functional programming is so compelling. FP is, among other things, about trusting what you see. 
While the exact definition of *functional programming* is still subject to some debate, one well-established characteristic is to maximize the use of
functions in the mathematical sense. These functions are

- referentially transparent, or *side-effect free*, which means they only bind some input to some output, i.e., they do nothing more than suggested by their signature
- total, which means they are defined for the entire set of arguments they may receive, i.e., they do nothing less than advertised either

Together, these characteristics ensure that you can understand the code at hand quickly, and refactor it with confidence. 

So clearly, methods that throw exceptions don't fit this definition. Throwing exceptions usually means failing on a particular subset of arguments,
or under specific circumstances, which breaks the rule of totality. We need another way of modeling errors,
and I believe the frustration caused by traditional error handling patterns alone is enough to motivate the learning of something else entirely.

So, if not exceptions, what then?

## Making exceptions exceptional again

To make the invisible errors visible again, we need to stop encoding them as exceptions and start encoding them as regular data. We need a way of showcasing
they error cases of our methods directly in their signatures, so they don't surprise anyone anymore, and we need a way of composing error-prone code safely, because
we're not writing our entire application in a single function, right?

One of the way we can turn errors into data is by using `Option` to model the potential absence of value, and `Either` to model computations that may fail while associating
additional data to the failure. I will introduce some examples of using these structures to handle errors, but I won't dwell on them too much, 

Let's bring our first example back. If we were to refuse the user a discount in certain cases, instead of throwing an exception, we can expand the return type of our function
by using an `Option` instead.

```scala
/**
* This never throws, for real this time.
*/
def computeDiscountedPrice(originalPrice: Float, discountPercent: Float): Option[Float] = {
  if (discountPercent > 75) None
  else Some(originalPrice - (originalPrice * discountPercent / 100))
}
```

This time, the function never throws. Instead, it returns a data type that encodes optionality, leaving the caller responsible for handling every possible case (and if they
don't, the compiler will warn them)

```scala
val validDiscount = computeDiscountedPrice(999.95F, 20.0F) // Some(799.9600219726562)
val invalidDiscount = computeDiscountedPrice(999.95F, 77.00F) // None
```

Great! No more exceptions blowing up in our faces. Now I know that sometimes this can fail, and I will adapt my code accordingly. But in what circumstances exactly?
`Option` doesn't give us any detail as to why a value is absent, it just is, deal with it. In some cases it is desirable to convey additional information regarding the nature
of the error. For these situations, using an `Either` 

## Monads, a short definition

## IO monads, why do we care?

## Error handling using Cats Effect's IO

## Domain edge cases vs. technical failures. Don't mix them up!

## The difficulty of combining effects

## Combining effects with monad transformers

## A short detour : tagless final

## Introducing Cats MTL

## Examples and conclusion