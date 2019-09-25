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

Type classes are a very common pattern in Scala. My goal in this post is to demistify what
they are, how they are useful, and how they are supposed to evolve in the next big iteration of Scala,
currently known as Dotty.

## Why do we need type classes ?

Type classes are a programming technique that allows you to define common behavior for
multiple types. Type classes act as a kind of interface, providing a common way of interacing with
multiple types, while each of those type have different concrete implementation for this interface.

However, type classes differ from interfaces in the OOP world, as you don't need to *own* the type
to add new behavior to it. You can use type classes to define new functions for closed types such as
final classes, or even types that come from the standard library or external dependencies. Type classes
are used extensively in functional programming libraries like [Cats](https://typelevel.org/cats/), whose point
is to provide abstractions over data transformation across many different types, including the one you write yourself
in your projects.

## Implementing your own type classes

Type classes are not a feature of the Scala programming language, they are a *pattern* that relies on
existing features such as traits and impicits. A type class is usually composed of a three things :

- The type class itself, a trait that lists the common operations of all the members of the class
- Instances of the type class for every member : once you have defined what your operations will be in abstract
terms (*i.e.* using generic type parameters), you need to define what this *contract* means for every member.
- Some interface that exposes the type classe's operations

For the purpose of this article, we will create a `Reversible` type class that defines reversal semantics for
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

This *kind of* works if we now exaclty the type of `Reversible` we're dealing with here, but the whole point
of type classes is to be able to use them as an abstraction, without knowing exactly what specific type
we're dealing with.

## Type classes you might already know

## Programming with effects

## Dotty and the future of type classes