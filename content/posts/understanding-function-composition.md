---
title: Function composition techniques for every developer
date: 2019-05-15
draft: true
tags:
  - Functional Programming
  - Javascript
---
Today I'd like to introduce some of the most fundamental techniques we use
every day in functional programming to build programs out of smaller units. Wether you're getting
started in the Lamda world, or a well installed developer looking for techniques to refactor a huge piece
of code, I hope you'll find these helpful. All you need is a programming languages that supports
functions as first-class citizens, sometimes referred to as lamda expressions (Javascript, C#, Go, Scala, PHP ...).

In this article we will cover

- Highher-order functions
- Function composition
- Partial application
- Currying

Let's go!

## What are functions exactly ?

If you're a developer, you're very likely already familiar with the term *function*, so much so, that it
might be difficult to give it a concise definition. I like to think of functions as very simple things : *arrows*
that map one particular value of a set to a particular value of possibly different set. 
Let's say you have two sets, `Day` and `ChuckNorrisQuote` and function that goes `f: Day -> ChuckNorrisQuote`,
then when you apply `f` to a particular day `April 1st`, you get a particular Chuck Norris quote, that is said to
be the image of `April 1st` by `f`.

In programming, functions sometimes accept more than one value as arguments. The number of arguments a function takes
is known as its *arity*. When a function requires both an instance of `Date` and a `Movie`, we say is has an arity of two.
A function that expects exactly one argument is said to be *unary*. In some languages, arity is a core part of the function's,
definition, like in Elixir, where the fully qualified name for function is `name/arity`. In others, like Javascript, you can
pass any number of arguments to any function, the validity of the argument set has to be checked at runtime. We'll reuse 
the term *arity* later on.

Now, you may already know that functional programmers, programmers that use functions as the primary building
block of all programs, like to put some adjectives on their functions : they say functions should be *pure*, 
*total*, *referentially transparent* ...I'm not going into too much details about what this means, that's a topic
for another day, but I'd like to emphasize something else instead : often, in programming, we use the term *function*
where what we really mean instead is *subroutine* or *procedure*, i.e something that we use to group lines
of codes together so we can re-use them later. These procedures often don't have return values, they're only
used for their side effects, and sometimes they don't even have arguments. Procedures have their use cases, but they're
not quite the same concept as functions. For the sake of this article, we'll only consider the simplest definition
of a function, an arrow from a set to another, and see what we can get from this simple yet powerful concept.

## Functions are values

In languages that support functional programming, functions are first-class values. They can not only be defined and
invoked, but also passed around like strings, objects and numbers. Functions can thus take other functions as arguments,
or even return new functions. We call such functions higher-order functions. Higher-order functions can be stored in
variables, put in arrays or inside objects. You can do pretty much anything with them.

This enables another level of abstraction that can help you dramatically reduce the size of your program, meaning it 
will improve its maintainability. Whith higher-order functions, you can abstract not only over values, but also over
behaviour. Passing functions around allow you to factorize multiple behaviours into a single, more generic one.

Let's use an example here. Imagine you want to count vegetables in a cart that looks like this :

```Javascript
const cart = [
  { category: "veg",   name: "Carrot",                     qt: 6 },
  { category: "books", name: "The Alternative Hypothesis", qt: 1 },
  { category: "veg",   name: "Potato",                     qt: 5 },
  { category: "veg",   name: "Lettuce",                    qt: 1 },
  { category: "books", name: "The Grapes of Wrath",        qt: 1 },
]
```

You could write a function that looks like this :

```javascript
const countVegetables = cart => {
  let count = 0
  for (let i = 0; i < cart.length; i++) {
    if (cart[i].category === "veg") {
      count += cart[i].qt
    }
  }
  return count
}
```

This would work fine, but if you'd like to also count books, you would need another function to do so. This is
a lot of code duplication for such a simple task. Let's see how we can improve this.

```javascript
const countCategory = (category, cart) => {
  let count = 0
  for (let i = 0; i < cart.length; i++) {
    if (cart[i].category === category) {
      count += cart[i].qt
    }
  }
  return count
}

const vegetablesCount = countCategory("veg",   cart)  // 3
const booksCount      = countCategory("books", cart) // 2
```

This is a little bit better : using a string argument, we are able to abstract over the name of the category. We
now have a function that can count every category we'd like. But this isn't enough, because now your boss wants you
to count items with a quantity of five or more. How can we do this without entirely rewriting our function ? 

We start by asking ourselves what those three tasks, counting vegetables, counting books, and counting items by with
a given quantity have in common. We notice that every time, we iterate over the cart, filter the items based on a
condition, and update a counter. Those are the parts that won't change. What we need is a way to abstract over the
condition of our filter. Let's see how to do that with HOFs : 

```javascript
const countBy = (predicate, cart) => {
  let count = 0
  for (let i = 0; i < cart.length; i++) {
    if (predicate(cart[i])) {
      count += cart[i].qt
    }
  }
  return count
}

const vegetablesCount = countBy(item => item.category === "veg",   cart) // 3
const booksCount      = countBy(item => item.category === "books", cart) // 2
const itemsWithHighQt = countBy(item => item.qt >= 5,              cart) // 2
```

As you can see, most of the function's body is left unchanged. Our `countBy` function now expects another function as its
first argument that we call a `predicate`. This predicate will be called with the current element of the iteration, i.e. a
cart item, and return whether or not this item should be counted. This enables us to count items based on any condition
we'd like.

### Taking advantage of `filter` and `reduce`

This use-case, filtering over an array and eventually counting the results, is very common. So much so that many languages
already have higher-order functions to do that, including Javascript.

The `filter` method allows you to filter the items of an array based on a predicate, and the `reduce` method allows you
to combine the items of an array into a single value.

```javascript
const countBy = (predicate, array) =>
  array.filter(predicate).reduce((count, currentItem) => count + currentItem.qt, 0)
```

We start by filtering using our predicate, we're left with an array containing only the items we care about. Then
we use `reduce` to add the quantities together. `reduce` takes care of managing an accumulator (our `count` variable) from
above) and doing the iteration for us. It expects us to give it a function that will be applied to every item of the array
with the current value of the accumulator. The function should return whatever the new value of the accumulator should
be after the `currentItem` has been taken into account. Optionally, `reduce` allows us to pass it an initial value that
will be the value of the accumulator on the first iteration. Here, that value is `0`. 

Reduce can be confusing at first, but it's a very common tool. If you don't feel quite comfortable with it,
I recommend you read 
[this article](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce) from 
the Mozilla Developer Network and practice reducing arrays. Try calculating sums, finding averages or 
re-implementing the `join` method. 

## Functions compose

A key property of functions is that smaller functions can be composed to create new functions. That's how we build larger
scale programs in functional programming. Composition is a simple and essential concept : it is the idea that if you
have a function from `User` to `Day` (let's say it's their birthday), and a function from `Day` to `ChuckNorrisQuote`, then
composition gives you a function from `User` to `ChuckNorrisQuote`.

To express it more generically, we say that composing functions is applying a function to the result of another function.
In mathematics the symbol `º` is used to express this composition. 

```
f(x) = 2x + 3
g(x) = 4x

c(x) = (gºf)(x) = g(f(x))

c(12) = g(f(12))
      = g(27)
      = 108
```

## Functions can be partially applied


## Where do I go next ?

I hope you liked this introduction on functional composition. If you're JavaScript developer, I recommend that
you try out Ramda, a utility library that emphasizes on function composition. [I made a blog post on it too](/blog/discover-ramda).
They are also functional programming libraries in many langauges such as [Arrow](https://arrow-kt.io) 
for Kotlin or [Functional PHP](https://github.com/lstrojny/functional-php).

If you want to dive deeper in the functional programming world, I'd suggest you pick and try to learn a functional language such as
ReasonML or Scala. Be careful though, some languages are more opinionated than others : Scala for example is very permissive due to its
interoperability with Java. If it's your first time learning a functional language, I'd recommend you to go with something more opinionated,
with well established functional patterns. If you chose Scala, I really recommend you learn Cats, a functional programming library, and keep
away from the LIghtbend ecosystem, at least at the beginning. [Scala Exercises](https://www.scala-exercises.org) is a good way to start.

In the meantime, keep calm and curry-on !