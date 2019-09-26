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
are used extensively in functional programming libraries like [Cats](https://typelevel.org/cats/), whose point
is to provide abstractions over data transformation across many types, including the one you write yourself
in your projects.

## Implementing your own type classes

Type classes are not a feature of the Scala programming language, they are a *pattern* that relies on
existing features such as traits and implicits. A type class is usually composed of a three things :

- The type class itself, a trait that lists the common operations of all the members of the class
- Instances of the type class for every member : once you have defined what your operations will be in abstract
terms (*i.e.* using generic type parameters), you need to define what this *contract* means for every member.
- Some interface that exposes the type class' operations

For the purpose of this article, we will create a 'Reversible' type class that defines reversal semantics for
our types.

### 1) Defining the contract

Our `Reversible` type class will take a single type parameter `A`, the type we want to *reverse*, and will be
composed of a single `reverse` method that takes an `A` and returns a reversed `A`.

```scala
trait Reversible[A] {
  def reverse(input: A): A
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
object ReversibleInstances {
  
  implicit val reversibleString = new Reversible[String] {
    def reverse(input: String): String = input.reverse
  }

}
```

As you can see, the `Reversible` instance for `String` is pretty straight-forward : we simply reuse the `reverse`
method that Scala (or rather *Java* in that case) provides on all strings for us. We've put the instance in a 
seperate object. This is not required, it's up to you to decide how you want to organize your code base.

Now, let's define our `Ratio` class and its associated behavior:

```scala
case class Ratio(numerator: Int, denominator: Int)

object ReversibleInstances {
  // ...
  implicit val reversibleRatio = new Reversible[Ratio] {
    def reverse(input: Ratio): Ratio = Ratio(input.denominator, input.numerator)
  }
}
```

### 3) Defining an interface for your type class

Now that we have defined our instances for the members of our type class, we need to expose a way
for the users to use our type class. 

Right now, if we want to use our `Reversible` type class, we need to call the instance we want to use
explicitly like so : 

```scala
reversibleString.reverse("abcd") // => "dcba"
```

This *kind of* works if we know exaclty the type of `Reversible` we're dealing with here but there are some
issues with this approach

- this is a bit verbose
- the point of type classes is to be able to use them as an abstraction, without knowing exactly what specific type
we're dealing with

By using Scala's implicit classes and implicit parameters, we are able to expose our type class in a way that 
makes calling it very natural, while ensuring correctness at compile time.

```scala
implicit class ReversibleOps[A](a: A)(implicit evidence: Reversible[A]) {
  
  def reverse = evidence.reverse(a)

}
```

By defining this `implicit class`, we are able to call our `reverse` method just like it was defined
directly on the member :

```scala
val reversedString = "fooBar".reverse // => "raBoof"
val reversedRatio = Ratio(2, 12).reverse // => Ratio(12, 2)
```

#### How does this work ?

This "magic" relies on two features of Scala : implicit classes and implicit arguments. To put it
shortly :

- implicit arguments (arguments prefixed with the 'implicit' keyword) are *resolved* by searching the current scope
for implicit 'val's or 'def's of matching type. Implicit resolution happens at compile time, meaning you
can't "forget" an implicit parameter.
- implicit classes, a particular occurrence of a broader feature call *implicit conversion*, are classes
that are automatically instantiated for you by the compiler, so that if you have a type 'T', and an implicit class
whose constructor takes a single 'T' as argument, you can call the implicit class' methods directly on all 'T' without
having to instantiate the class manually

Let's get back to our example. Given that you have:

- a generic trait `Reversible[A]` where `A` can be anything
- an implicit class `ReversibleOps` that takes any type `A` as an argument and some implicit instance
`Reversible[A]`
- an implicit instance of the `Reversible` type class for some type `Ratio`, that will act as a *proof* that A
is indeed a member of the `Reversible` and provide a concrete implementation for the abstract methods defined by
`Reversible`

Then you can write

```scala
val reversedRatio = Ratio(10, 20).reverse
```

and the compiler will rewrite it for you to

```scala
val reversedRatio = new ReversibleOps[Ratio](Ratio(10, 20))(evidence = reversibleRatio).reverse
```

The key take-aways here are :

- a type class needs three things : a generic trait, implicit implementations of that trait, some interface. If
you forget one of these things, you won't be able to use your type class like above
- anything you can do with implicits, you can also write explicitly. It's not totally dark magic. By trying 
to call your type class explicitly, you can understand better how implicits work, and debug compilation errors that
might occur.

## Programming with effects

As mentioned earlier, type classes are so useful in Scala, some major libraries such as Cats could not
exist without them. As a matter of fact, 
[Cats has a very good explaination about type classes in its documentation](https://typelevel.org/cats/typeclasses.html).

Cats uses type classes to model mathematical abstractions such as `Functor`, `Semigroup` or
`Monad`. While they sound scary, these abstractions are tremendously useful as they can express composition and data
transformation in generic ways, allowing you to reuse the same skills to manipulate different types as long 
as they fall under the same *laws*.

But this isn't a post bout Cats or the abstractions it provides, I don't intend to cover them in details. Instead,
I'd like to tell you about the *kind of programming* type classes enable.

## Dotty and the future of type classes