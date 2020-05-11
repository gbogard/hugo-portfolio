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
the error cases of our methods directly in their signatures, so they don't surprise anyone anymore, and we need a way of composing error-prone code safely, because
we're not writing our entire application in a single function, right?

One of the ways we can turn errors into data is by using `Option` to model the potential absence of value, and `Either` to model computations that may fail while associating
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
val validDiscount = computeDiscountedPrice(999.95F, 20.0F)    // Some(799.9600219726562)
val invalidDiscount = computeDiscountedPrice(999.95F, 77.00F) // None
```

Great! No more exceptions blowing up in our faces. Now I know that sometimes this can fail, and I will adapt my code accordingly. But in what circumstances exactly?
`Option` doesn't give us any detail as to why a value is absent, it just is, deal with it. In some cases it is desirable to convey additional information regarding the nature
of the error. For these situations, using an `Either` instead allows us to fail with a particular value, as demonstrated by the next example:

```scala
def computeDiscountedPrice(originalPrice: Float, discountPercent: Float): Either[String, Float] = {
  if (discountPercent > 75) Left("The discount cannot exceed 75%, that would ruin us!")
  else Right(originalPrice - (originalPrice * discountPercent / 100))
}

val validDiscount = computeDiscountedPrice(999.95F, 20.0F)     
// Right(799.9600219726562)
val invalidDiscount = computeDiscountedPrice(999.95F, 77.00F)  
// Left(The discount cannot exceed 75%, that would ruin us!)
```

When we want to enforce a particular condition, there's even a shorter way of doing it:

```scala
def computeDiscountedPrice(originalPrice: Float, discountPercent: Float): Either[String, Float] =
  // Either.cond requires a boolean
  Either.cond(
    discountPercent <= 75,
    // When true, return this wrapped in a Right 
    originalPrice - (originalPrice * discountPercent / 100),
    // When false, return this on the left side instead
    "The discount cannot exceed 75%, that would ruin us!"
  )
```

Note that I chose a `String` as my error type on the left side, but I could have chosen any other type. In practice, I would against using `String` on the left side,
and use a sealed type instead, something I will do in further examples. There are two main reasons for this:

- First, there is no way to enforce exhaustivity when matching against strings. This means the compiler will be able to tell when you haven't handled *any error*, but not
that you haven't handled *all the errors*. Sealed types give you this additional safety.
- Secondly, recall how I like my function signature to tell as much as possible? Well, in that case, I know that the method may fail with a message, which is definitely
an improvement, but because a `String` is a very versatile structure, I still have to look at the implementation to know what this message may be. If I use a type
purposefully crafted to model the edge cases of my domain, the name of the type itself can tell me a lot about the nature of the error. Let your types tell the story,
and the implementations will be obvious.

## Monads, a short and probably imperfect definition

## IO monads, why do we care?

So, monads encode some functional *effect*. The `IO` monad, which you can find an implementation of in the *Cats Effect* library, is another member of this
big family, aiming at encoding side effects and asynchronicity. Consider the following signature:

```scala
def getUser(id: String): IO[User]
```

A value of type `IO[User]` is the representation of a likely impure program that has been turned into a referentially transparent value by *suspending* its execution.
Or to put it differently, it's a value representing a program that will run for an undetermined amount of time, probably has some side effects like connecting to an
external service, and will eventually yield a value of type `User`. Contrarily to Scala's `Future`, it isn't a handle to a computation running on another thread, merely
the blueprint of a program waiting to be explicitly ran.

Because they suspend side effects, `IO`s can be passed around freely and without risks. When chaining them, using `flatMap` like you would any monad, the resulting
composition is itself a lazy representation. The entire program will not run until you call something like `unsafeRunSync` on it. The side effects will run eventually, sure,
but at least not without your explicit consent. 

```scala
val a = IO(println("- Hello there"))
val b = IO(println("- General Kenobi!"))

// Nothing gets printed yet

(a >> b).unsafeRunSync()
// - Hello there
// - General Kenobi!
```

There is a bit of a debate among functional programmers to decide whether or not IO monads really make impure code pure. Which side you stand on is really a matter of definition.
Even when working with `IO`, your side effects will not magically disappear, they will run eventually. One could say, for the sake of exactitude,
that IO monads are pure up until execution i.e., they are pure representations of impure programs which lose their purity when you run them. But, of course, you are going to run them at
some point, so the distinction is of little value when you just want to ship quality code to production. 

One thing that appeals to theorists and hackers alike though is that `IO`
*reveals* the presence of side effects. Using `IO` is like highlighting dangerous code using types: the non-deterministic parts of your app are clearly segregated from the rest, inviting
authors and reviewers to greater caution. This property is called *effect tracking*. Sadly, in an impure language like Scala, effect-tracking only works if all other functions are
assumed to be pure by convention, there is no way for the compiler to enforce it. Relying on types to track effects, model errors and prevent impossible states is great and will
offload a great deal of mental charge, but it works best when everyone strives for pure functions; a reminder that shipping good code is a team effort.

## Error handling using Cats Effect's IO

The `IO` from Cats Effect, and some other implementations as well, allows their users to *raise* instances of `Throwable` inside the `IO` context, propagate them
across a chain of `IO` when composing, and recover them at some point, much like you would use traditional `throw` statements.

```scala
val failedIO: IO[Int] = IO.raiseError(new Exception("Boom!"))

failedIO.recoverWith({
  case e => IO {
    logger.error("Something went wrong", e)
    42
  }
}).unsafeRunSync()
```

There is subtle difference between raising errors inside `IO`s and throwing in the traditional sense. 
The former merely returns a value that encodes a failed program; it will fail only when explicitly ran. 
The latter interrupts the execution before returning any value:

```scala
// This always returns a value. When composed, all the subsequent IOs will fail too.
def getUser: IO[User] = IO.raiseError(new Exception("No user found"))

// This fails before getting a chance to return an IO.
// It means the program will fail during its construction, not during execution
def getUser: IO[User] = throw new Exception("No user found")
```

Throwing exceptions outside of `IO`s while the consumer expects to always get some value is confusing and dangerous. Please don't do it!

### The use case: modeling an authentication flow

For the rest of this post, I will introduce several error-handling strategies by highlighting the differences in implementing this simple use case:

I want to authenticate a user using a name and a password. My authentication method will return the user's information. After I have found the user
and ensured that their password matched the given input, I also need to enforce a couple of business rules:

- The user must have a valid subscription (this probably requires to call some billing service)
- The user must not be banned from using the service (probably enforced by calling some moderation component)

Each step of the process is a potential source of errors. And since there is a lot of external data fetching, `IO`s will be necessary here.
For each error-handling strategy, I will implement the authentication method by composing smaller programs using monadic composition.
Let's start with the most straightforward approach: raising exceptions inside `IO`s.

I will start by modeling every possible error as a bunch of case objects, every one of them inheriting from `RuntimeException`. That way they can not only
be thrown, which is required by `raiseError`, but also be pattern-matched against, which will make our life much easier.

```scala
case object WrongUserName extends RuntimeException("No user with that name") 
case object WrongPassword extends RuntimeException("Wrong password")
case class ExpiredSubscription(expirationDate: Date) 
  extends RuntimeException("Expired subscription")
case object BannedUser extends RuntimeException("User is banned")
```

Then, I split my logic into small, composable programs. I'll leave the implementation up to you here, I want to focus on the signatures instead. It should be clear enough
what each program is meant to do.

```scala
def findUserByName(username: String): IO[User] = ???
def checkPassword(user: User, password: String): IO[Unit] = ???
def checkSubscription(user: User): IO[Unit] = ???
def checkUserStatus(user: User): IO[Unit] = ???
```

Once I have these programs, I can compose them using `flatMap`. I'll use a for-comprehension here because it's easier to read, but remember it's merely syntactic sugar for good ol'
`flatMap`.

```scala
def authenticate(userName: String, password: String): IO[User] =
  for {
    user <- findUserByName(userName)
    _ <- checkPassword(user, password)
    _ <- checkSubscription(user)
    _ <- checkUserStatus(user)
  } yield user
```

This method first attempts to find my user, then verifies every business rule one after the other, and finally returns my user if everything went well. If any of these intermediate
programs raises an exception, the execution of the entire composition will be aborted, and my `authenticate` method will itself return a failed `IO` with whatever went wrong.
Note that right now, all the checks are made in series cause that's how monads work, but since we are using `IO` and since the program is most likely bound by rhe network,
independent checks could be done in parallel for improved performance. Have a look at [start/join](https://typelevel.org/cats-effect/datatypes/io.html#concurrent-start--cancel) 
to see how it can be achieved. 

Once I have my intermediate programs all composed together, I can call my `authenticate` method and choose what to do with my user. Eventually, I will also have to `recover` my
various errors.

```scala
authenticate("john.doe", "foo.bar")
  .flatMap(user => IO {
    println(s"Success! $user") })
  .recoverWith({
    case WrongUserName => IO { /* Do stuff ... */ }
    case WrongPassword => IO { /* Do stuff ... */ }
    case ExpiredSubscription(date) => IO { /* Do stuff ... */ } 
    case BannedUser => IO { /* Do stuff ... */ }
    case _ => IO {
      println("Another exception was caught !") }
  })
```

This works, however this approach is fundamentally flawed. Errors appear nowhere in the signature of the `authenticate` method, making it impossible to know about them
without some knowledge of the implementation. We've solved the *effect tracking* part by revealing the presence of side effects using `IO`, that's an improvement, but we 
still have to document errors explicitly, just like we would have to if we were throwing exceptions around and catching them.

Remember that when composing `IO`s together to form a bigger program, raised exceptions propagate across the entire composition, making them nearly as deadly as regular `throw`s. 

There is another issue with this: since `IO`s from Cats Effect can only raise and recover descendants of the `Throwable` type, there is no way to know for sure that I have caught
all my business errors, because we can't perform an exhaustive pattern matching on `Throwable`.
This is why I have to add a final `case _ =>` in my pattern matching expression for the sake of exhaustivity. But then if I recover *all* exceptions, how can I know
that I have handled all my business errors properly, and that none of them will match my final *catch-all* branch?

- I want my errors to appear clearly in the signature of my methods so I don't have to know so much about the implementation
- I want to treat every error specifically to give actionable feedback to my users
- I want the compiler to tell me when I forget to handle an error

In other terms, I want my error handling to be truly type-safe. We will address all these concerns in a moment, but first I'd like to clarify something.

## Domain edge cases vs. technical failures. Don't mix them up!

## The difficulty of combining effects

## Combining effects with monad transformers

## A short detour: tagless final

## Introducing Cats MTL

## Examples and conclusion