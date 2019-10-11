---
title: "Understanding Type classes in Scala : extending types you don't own"
date: 2019-09-23
categories:
  - scala
tags:
  - scala
  - functional programming
  - polymorphism
---

Type classes are a very common pattern in Scala. My goal in this post is to demystify what
they are, how they are useful, and how they are supposed to evolve in the next big iteration of Scala,
currently known as Dotty.

## Why do we need type classes ?

Type classes are a programming technique that allows you to define common behavior for
multiple types. Type classes act as a kind of interface, providing a common way of interacting with
multiple types, while each of those type have different concrete implementation for this interface.

However, type classes differ from interfaces in the OOP world, as you don't need to *own* the type
to add new behavior to it. You can use type classes to define new functions for closed types such as
final classes, or even types that come from the standard library or external dependencies. Type classes
are used extensively in functional programming libraries like [Cats](https://typelevel.org/cats/), which
provides abstract data transformation that you can use on types from the standard library as well as your own types.

## Implementing your own type classes

Type classes are not a feature of the Scala programming language, they are a *pattern* that relies on
existing features such as traits and implicits. A type class is usually composed of a three things :

- The type class itself, a trait that lists the common operations of all the members of the class
- Instances of the type class for every member : once you have defined what your operations will be in abstract
terms (*i.e.* using generic type parameters), you need to define what this *contract* means for every member.
- Some interface that exposes the type class' operations

For the purpose of this article, we will create a 'Inversible' type class that defines reversal semantics for
our types.

### 1) Defining the contract

Our `Inversible` type class will take a single type parameter `A`, the type we want to *inverse*, and will be
composed of a single `inverse` method that takes an `A` and returns an inverse `A`.

```scala
trait Inversible[A] {
  def inverse(input: A): A
}
```

Thanks to the use of a generic type, we can apply this type class to whatever type we want.

### 2) Implementing the instances

For now we only have a `trait` with no actual behavior, a *contract* of what our members should implement.
It's up to you to define what the members of this type class will be, and how they should implement this contract.
We will implement instances for the `String` type of the standard library, as well as for a custom
`Ratio` case class.

Let's begin with the standard library:

```scala
object InversibleInstances {
  
  implicit val inversibleString = new Inversible[String] {
    def inverse(input: String): String = input.reverse
  }

}
```

As you can see, the `Inversible` instance for `String` is pretty straight-forward : we simply reuse the `reverse`
method that Scala (or rather *Java* in that case) provides on all strings for us. We've put the instance in a 
separate object. This is not required, it's up to you to decide how you want to organize your code base.

Now, let's define our `Ratio` class and its associated behavior:

```scala
case class Ratio(numerator: Int, denominator: Int)

object InversibleInstances {
  // ...
  implicit val inversibleRatio = new Inversible[Ratio] {
    def inverse(input: Ratio): Ratio = Ratio(input.denominator, input.numerator)
  }
}
```

### 3) Defining an interface for your type class

Now that we have defined our instances for the members of our type class, we need to expose a way
for the users to use our type class. 

Right now, if we want to use our `Inversible` type class, we need to call the instance we want to use
explicitly like so : 

```scala
inversibleString.inverse("abcd") // => "dcba"
```

This *kind of* works if we know exactly the type of `Inversible` we're dealing with here but there are some
issues with this approach

- this is a bit verbose
- the point of type classes is to be able to use them as an abstraction, without knowing exactly what specific type
we're dealing with

By using Scala's implicit classes and implicit parameters, we are able to expose our type class in a way that 
makes calling it very natural, while ensuring correctness at compile time.

```scala
implicit class InversibleOps[A](a: A)(implicit evidence: Inversible[A]) {
  
  def inverse = evidence.inverse(a)

}
```

By defining this `implicit class`, we are able to call our `inverse` method just like it was defined
directly on the member :

```scala
val inverseString = "fooBar".inverse // => "raBoof"
val inverseRatio = Ratio(2, 12).inverse // => Ratio(12, 2)
```

#### How does this work ?

This "magic" relies on two features of Scala : implicit classes and implicit arguments. To put it
shortly :

- implicit arguments (arguments prefixed with the 'implicit' keyword) are *resolved* by searching the current scope
for implicit `val`s or `def`s of matching type. Implicit resolution happens at compile time, meaning you
can't "forget" an implicit parameter.
- implicit classes, are classes that are automatically instantiated for you by the compiler,
so that if you have a type 'T', and an implicit class whose constructor takes a single 'T' as argument, 
you can call the implicit class' methods directly on all 'T' without having to instantiate the class manually.

Let's get back to our example. Given that you have:

- a generic trait `Inversible[A]` where `A` can be anything
- an implicit class `InversibleOps` that takes any type `A` as an argument and some implicit instance
`Inversible[A]`
- an implicit instance of the `Inversible` type class for some type `Ratio`, that will act as a *proof* that `Ratio`
is indeed a member of the `Inversible` type class and provide a concrete implementation for the abstract methods it defines.

Then you can write

```scala
val inverseRatio = Ratio(10, 20).inverse
```

and the compiler will rewrite it for you to

```scala
val inverseRatio = new InversibleOps[Ratio](Ratio(10, 20))(evidence = inversibleRatio).inverse
```

The key take-aways here are :

- a type class needs three things : a generic trait, implicit implementations of that trait, some interface. If
you forget one of these things, you won't be able to use your type class like above
- anything you can do with implicits, you can also write explicitly. It's not totally dark magic. By trying 
to insantiate your type class explicitly, you can understand better how implicits work, and debug compilation errors that
might occur.

## Programming generically with Type classes

One very interesting property of type classes is that they model *features* of a type in an abstract way. They enable *ad-hoc polymorphism*,
which is a fancy way of saying the same function can be applied to values of different types. We achieve that by using type class as a *bound* or *constraint*
over type parameters. 

Let's consider the following generic function :

```scala
def printMirror[A](value: A) = println(
  s"""
  |  $a  /
  |     /
  |    /   ${a.inverse}
  """.stripMargin
)
```

This wouldn't compile because the `value` parameter could be of any type, and the compiler doesn't know about an `inverse` method that works on any type. What is
supposed to happen when we call that method with a `Map[String, String]` or a `scala.concurrent.Duration` ? We need a way of restricting the type of values
`printMirror` can accept, so it can only be called with members of the `Inversible` type class, and the compiler knows where which implementation to use.

And we do that with implicit parameters.

```scala
def printMirror[A](value: A)(implicit evidence: Inversible[A])
```
You will also need to make sure that the `InversibleOps` implicit class is in the scope when you define the `printMirror` function, so the compiler knows
how to call the `inverse` method with infix dot notation.  

By adding an implicit parameter to the function's signature, we are able to tell the compiler 
"I don't care what this type is, but there must be some instance of Inversible for it somewhere.". And that *somewhere* is the 
*implicit scope* of the function call, which generally means either in the same object or in the imports.

Now that we this implicit parameter, we can use this function on any member of our type class, given our instances are in the *implicit scope* when we
call the function. For instance we can write

```scala
printMirror("Hello")
printMirror(Ratio(78/2))
```

But not `printMirror(45)`. In that case, the Scala compiler will tell us something like this 

```
could not find implicit value for parameter evidence: Inversible[Int]
```

Which tells ii tried to find an instance of Inversible for the type Int but failed to do so, either because you haven't defined it, or forgot to import it.

### Context Bound

Notice how in the example above, we defined an `evidence` parameter but didn't use it directly. This parameter exists merely to tell the compiler to put a constraint
on the `A` type. Since we don't *use* this parameter directly, it feels a bit like a waste of space. It turns out Scala has a shorter syntax for applying 
type class constraints to generic types. It's called *context bounds*, and it works like this :

```
def printMirror[A: Inversible](value: A)
```

is syntactic sugar for 

```scala
def printMirror[A](value: A)(implicit evidence: Inversible[A])
```

The type you put after the colon `:` in the brackets must expect exactly one type parameter. You will lose the ability to call the type class instance itself,
like you would if you had defined it as an implicit parameter, but you can regain this ability by using `implicitly` to search the implicit scope for the value
you want.

## Dotty and the future of type classes

Dotty is an experimental compiler for Scala that will eventually become Scala 3. The goal of Dotty is to
simplify and consolidate the language by promoting patterns that work well in Scala 2 and eliminating confusing
syntax and inconsistances.

With Dotty, implicits, the language feature that powers the type class pattern, have gone under a major rework.

The issue with the way implicits work in Scala 2 is that the `implicit` keyword is used everywhere to express three
different things :

- Implicit parameters, which we have used to provide the compiler an *evidence* that our types implement the type class we want
- Implicit classes, which we have used to have a nice method syntax for our type class operations
- Implicit conversions, which we haven't talked about

Using these three different things with the same keyword makes *implicits* unnecessarily hard for newcomers. In Dotty, the
naming has been made more consistent and new language features make writing type classes easier than before. Let's se how!

**NB : As of this post, the latest version of Dotty is `0.19.0-RC1`. Dotty is still under active development, and some of the syntax
shown below may change.**

### Extension Methods

Extension methods are methods you can add on a type after it is defined. To write an extension method, flip the arguments list and the
method identifier.

```scala
def (ratio: Ratio) inverse: Ratio = Ratio(ratio.denominator, numerator)

Ratio(30, 10).inverse // => Ratio(10, 30)
```

### Given instances

From the Dotty documentation

> Given instances (or, simply, "givens") define "canonical" values of certain types that serve for synthesizing arguments to given clauses

What does this mean for type classes ? Simply put, if you have a trait `Inversible[A]`, a "given" of type `Inversible[Ratio]` defines what the
implementation of `Inversible` should be for the `Ratio` type. It's very similar to implicit values. Let's use them to define instances 
for our `Inversible` type class :

```scala
trait Inversible[T] {
  def (input: T) inverse: T 
}

object Inversible {

  given stringInversible: Inversible[String] {

    def (input: String) inverse: String = input.reverse

  }

  given ratioInversible: Inversible[Ratio] {
    
    def (input: Ratio) inverse: Ratio = Ratio(input.denominator, input.numerator)

  } 

}
```

Notice how extension methods can be used directly in the definition of our type class. 

This is all we need to be able to call the `inverse` method on our types. No need for an implicit class to get the nice infix dot
syntax. However, there is a major difference with implicit values : if you defined your givens in a separate file from where you call them, 
you need to import them explicitly using a special import notation. This has been done to give you a greater granularity over imports.

```scala
import Inversible.given

object Main {

  def main(args: Array[String]): Unit = {
    print(
      Ratio(10, 45).inverse
    )
  }

}
```

### Wiring everything with Given clauses

Dotty's *given clauses* are used to specify a requirement that the Scala compiler will resolve for you using the given instances in the
current scope. They work much like Scala's implicit parameters.

```scala
def printInverse[A](input: A)(given Inversible[A]): Unit = 
  println(s"The inverse of $input is ${input.inverse}")
```

The main difference here is that given clauses can be anonymous, you don't have to name the parameter if you don't intend to use more than its
extension methods. And if you want something even shorter, you can use context bound just like in Scala.

To learn more about given clauses, check out [Dotty's documentation](https://dotty.epfl.ch/docs/reference/contextual/given-clauses.html).

### A complete type class example in Dotty

To illustrate this article better, I've put an example project on [Github](https://github.com/gbogard/dotty-typeclass-example) 
that illustrates all we've talked about.  [Feel free to check it out](https://github.com/gbogard/dotty-typeclass-example).

That sums up pretty much all there is to know to build type classes. If you want better examples of how type classes are useful to functional
programmers, check out the documentation of [Cats](https://typelevel.org/cats/typeclasses.html). Cats is a very powerful Scala library built almost
entirely with the type class pattern. And you will learn powerful data structures and transformations along the way!

Thank you for reading this introduction to Type classes and, until next time, keep calm and curry-on!