---
doi: 10.5281/zenodo.22828847
title: "Why ggseg Atlases Became Function Calls"
format: hugo-md
author: Dr. Mowinckel
date: "2026-09-17"
tags:
  - R
  - ggseg
  - package-development
  - namespaces
  - api-design
slug: atlases-as-functions
seo: |
  Why the ggseg atlases moved from lazy-loaded data objects to nullary
  functions: R cannot re-export a dataset from one package's namespace into
  another, and the whole ggsegverse depends on being able to.
summary: >
  Re-exporting lazy-loaded datasets is not possible in R-packages, since they don't exist in a package's namespace. This created a conundrum for me as I was reinventing how the ggseg-ecosystem would look like in the future. Here, I walk through the problem and solution I ended up with, with the help of good colleagues in rOpenSci.
image: data_door.png
image_alt: A 3D minimalist illustration comparing an open doorway to a bricked-off door. On the left, an open door glows with teal light, flanked by a giant pair of curved parentheses. Inside the doorway sits a glowing pedestal with a stylized brain outline and a small tag reading "dk()". On the right, a second door is completely walled off with grey bricks and a nameplate reading "dk". Below the doors, code text reads "ggplot() + geom_brain(atlas = dk())
---

A little while ago, I started doing quite some substantial work on ggseg-packages.
I wanted to make things more coherent, clear, a proper ecosystem of packages that could more easily be expanded upon.
In that work, I needed to make some hard decisions on how things should _work_ for the user, which collided with how they currently worked for the user.
Ick, it was hard to do something I knew would break so many people's code.

If you have used ggseg for a while, you have probably hit this:

```r
ggplot() + geom_brain(atlas = dk)
#> Error: `atlas` must be a <ggseg_atlas> object, not a function.
```

The fix is two characters.
Write `dk()` instead of `dk`, and everything works again.

```r
ggplot() + geom_brain(atlas = dk())
```

But two characters is not nothing when they are sitting in every analysis script you have written, every paper figure you might need to regenerate, and every teaching material you have handed to students.
So I owe you the reasoning.

## The thing I wanted to do

ggseg was once a package for plotting brains using ggplot, which then expanded into plotting 3d brains with ggseg3d, and creating new atlases with ggseg.extra.
It's been growing, and growing out of its beginnings, and mine.
When I started this project, I was a novice developer, and made some choices that were not great for the long-term maintenance of the ecosystem as a whole.
Mainly because I could not have imagined it evolving as it has, or having so many users.

ggseg is not one package anymore, it's a whole suite of them that we call ggsegverse[^ggsegverse].
It is [ggseg.formats](https://github.com/ggsegverse/ggseg.formats) holding the atlas classes and the bundled atlases, [ggseg](https://github.com/ggsegverse/ggseg) drawing them in 2D, [ggseg3d](https://github.com/ggsegverse/ggseg3d) drawing them in 3D, [ggseg.extra](https://github.com/ggsegverse/ggseg.extra) for creating atlases, and then a long tail of atlas packages like ggsegShen, ggsegSchaefer and ggsegGlasser.

The split is deliberate.
Atlas data is big and slow-moving; plotting code is small and may change more often.
I did not want a bug fix in `geom_brain()` to force everyone to re-download several megabytes of polygons.

But here is what a user reasonably expects.
You install ggseg, you type `dk`, you get the Desikan-Killiany atlas.
You install ggseg3d instead, you type `dk`, you get the same atlas.
You should not have to know or care that neither of those packages actually contains it.

That is a re-export.
Package A owns the thing, packages B and C offer it under their own names.

For a function, R makes this pleasant.
Three lines of roxygen in each package:

```r
#' @importFrom ggseg.formats ggseg_atlas
#' @export
ggseg.formats::ggseg_atlas
```

That is what sits in ggseg's package file, and again in ggseg3d's.

For a dataset, it is not so pleasant.

## Let me show you, rather than assert it

I did not want to take my own word for this, so I built the smallest possible demonstration.
Two throwaway packages. `pkgA` ships both a function and a dataset:

```r
# pkgA/R/a.R
dkfun <- function() "I am an atlas"

# pkgA/data/dkdata.rda contains
dkdata <- "I am an atlas"
```

`pkgB` tries to re-export both:

```r
# pkgB/NAMESPACE
importFrom(pkgA, dkfun)
importFrom(pkgA, dkdata)
export(dkfun)
export(dkdata)
```

Installing it:

```
** byte-compile and prepare package for lazy loading
Error: object 'dkdata' is not exported by 'namespace:pkgA'
ERROR: lazy loading failed for package 'pkgB'
```

There it is.
Drop the two `dkdata` lines and `pkgB` installs happily.

The reason is that a dataset in `data/` never enters the package's _namespace_ at all.[^namespace]
It lives in a separate lazy-load database that `::` knows how to reach into — `pkgA::dkdata` works fine — but `importFrom()` looks in the namespace, and the namespace does not have it.
There is no `export()` directive you can write to change that, because there is nothing in the namespace to export.

So the ggsegverse, as I wanted it to exist, was not buildable with atlases as data objects.

## Now what?

I was little at a loss on how to move forward.
I first added ggseg.formats to the packages `Depends` in the `DESCRIPTION`.
This genuinely works, it means loading `pkgB` automatically also loads `pkgA`, so everything in `pkgA` is immediately available, including the dataset.

But I also know from previous discussions with very good package developers that using `Depends` is generally not advised.
Indeed, running `goodpractice::gp()` (which I do for most my packages), did flag using Depends like this as bad practice.

Ok, next option to me seemed to be using a full package import.
Meaning, instead of importing distinct functions `@importFrom` I'd import the entire package catalogue with `@import`.
Goodpractice also flagged this as bad practice, and I was running out of options.

I decided to seek advice in the [rOpenSci](https://ropensci.org/community/) slack, where such discussions often occur, and are very enlightening and wholesome.
My initial question was which was best of these two options: `Depends` or full `@import`?
What followed was a very useful discussion, so let me walk through the options the way we actually walked through them, because every single one has a catch and I do not think any of it is obvious.

### Depends

[Jon Harmon](https://jonthegeek.com)'s instinct, and the conventional answer: put ggseg.formats in `Depends` rather than `Imports`, and its exports land on the user's search path when they attach ggseg.

This works and it is boring, which is usually a compliment.
The catch is that `Depends` is a blunt instrument.
It attaches the _entire_ package to the search path, not the three names I wanted, and the R community has spent a decade quietly agreeing that `Depends` is something you reach for rarely and apologetically.

It is also not what Jon himself would do.
His full answer was that he would _either_ split out the data package _or_ wrap it in a function — but that both of those were "more complicated and/or weirder" than what I already had.

### `.onAttach()` plus `data()`

[Gábor Csárdi](https://gaborcsardi.org)'s next suggestion, and this one has a nice twist.
Call `utils::data()` in `.onAttach()` to materialise the dataset when the package is attached.

I pushed back thinking it would put several copies of the same name on the search path if someone loaded both ggseg and ggseg3d.
I was overcomplicating it, though.
`data()` called twice for the same dataset is perfectly fine.

I also worried about `R CMD check` flagging undocumented objects, and Gábor showed that a clean check is achievable — `help()` searches loaded packages, so `?dk` would still resolve.

Then he worked out the actual problem himself:

> OTOH, just realized that `data()` just puts the object in `.GlobalEnv`, not the search path, so that's not great, either, probably worse than `Depends`.

And that is disqualifying.
A package that writes into your global environment when you attach it is doing something you did not ask for and cannot easily undo.
`Depends` at least puts things somewhere designed to hold them.

### So I wrote something clever (I thought), and then showed it to people

If the name cannot come in through `importFrom()`, I can put it in the namespace myself at load time:

```r
.onLoad <- function(libname, pkgname) {
  ns <- topenv(environment())
  for (obj in c("dk", "aseg", "tracula")) {
    local({
      name <- obj
      delayedAssign(
        name,
        getExportedValue("ggseg.formats", name),
        assign.env = ns
      )
    })
  }
}
```

And I want to be fair to this code: it works.
I rebuilt it in my toy packages to be sure, and it installs, the name exports, and `delayedAssign()` keeps it properly lazy so the big object is not pulled into memory just because someone loaded your package.
You keep `atlas = dk`.
Nothing breaks for anyone.

This was a function created by interpreting some suggestions in that slack discussion, but something with it felt... off.
I took it to the rOpenSci Slack with the question "this works, but does it smell?"[^smell], which is I think the correct question to ask about code like this.

Gábor's reply was four words: "That `.onLoad` definitely smells bad."

It does.
I knew it did.
I asked knowing what the answer was.

### A sibling trick I tested afterwards

For completeness, since I went looking: `makeActiveBinding()` in `.onLoad()` behaves much like the `delayedAssign()` version.
It installs, it re-exports through `importFrom()` into a second package, and it stays lazy.

Same smell, same objection.

### Functions

Where Gábor landed:

> TBH personally I would probably try to work around by creating functions to access the data, and then exporting/importing the functions, but YMMV.

Which is where Jon had gestured at the top of the thread too, filed under "weirder".

Two people who know R's package machinery considerably better than I do arrived at the same place independently, having first watched me demonstrate that the clever version worked.
That is about as strong a signal as you get.

I will admit my honest reaction in the moment was mild dismay: "I really didn't know I was trying to do something so unorthodox."
Because it did not _feel_ unorthodox.
Shipping data in a data package and using it from a plotting package is the most ordinary thing in the world.
It is only unorthodox because of where R draws the line between a namespace and a lazy-load database, and you do not find that line until you slam into it.

## What I picked, and what it costs

A nullary[^nullary] function per atlas.
The implementation is as boring as it gets:

```r
dk <- function() .dk_atlas
```

`.dk_atlas` is an internal object in `R/sysdata.rda`, which lazy-loads from the package database like everything else.
The function is a thin door onto it.

Every atlas package in the ecosystem now has exactly this shape.
Here is ggsegShen, doing what ggseg.formats does:

```r
#' @export
#' @examples
#' shen268_cortical()
shen268_cortical <- function() .shen268_cortical
```

It's not _necessary_ for all the atlas packages, really only for the default atlases shipped through ggseg.formats.
But I thought it would be cleaner to apply the same logic everywhere, and then others could also re-export the atlases in other packages if they wanted.

And it buys things none of the alternatives bought all at once.
It re-exports with three lines of roxygen.
Each atlas gets its own help page with its own references section, which for atlases genuinely matters — people need to cite the parcellation they used.
Tab completion works, static analysis works, and `dk` is honest about being a function rather than a name that quietly runs code when you look at it.
And the door stays open: the day I want `dk(surface = "inflated")`, the signature is already there to grow into.

That last point is the one that retroactively justifies the whole thing for me.
The `.onLoad` version was not just smelly, it was a one-way door.
An active binding or a delayed assignment can never take an argument, so the first time I needed one I would have been breaking everyone's code anyway — except by then with more users, and after having promised them it was stable.

Now the cost, which is real.

This was a hard break, shipped in ggseg 2.0.0.
`atlas = dk` does not warn and degrade, it errors.
Every script, every `.Rmd` that regenerates a figure, every workshop notebook — if it passed a bare atlas object, it stopped working.
Some of the people this happened to were mid-revision on a paper, which is close to the worst possible moment for your plotting code to break.

I do not think I could have avoided the break itself.
A deprecation path needs the old name to still resolve to something useful, and once `dk` is a function, `atlas = dk` is a function object.
I can detect that exact case and throw a message that tells you to add parentheses, which is what happens now.
I cannot make it keep working.

What I could have done better was say it earlier and louder — ahead of the release, not in the NEWS file of it.
That part is on me.

## The takeaway, if you are designing something similar

If you are building an ecosystem of R packages where one package owns data and others surface it, decide this early, because it is not really a data question.
It is a namespace question.

The moment you want a second package to offer the same object under its own name, you have chosen the namespace.
A function is the honest way to put something there.

The parentheses are not decoration.
They are the visible edge of that decision.

And the other takeaway, which is less about R: I had working code, I felt something was off about it, and I showed it to people anyway.
The clever version would have shipped, and it would have been fine, right up until it wasn't.
Ask the smell question out loud.
Someone will tell you.

If you want to see the result in place, [ggseg.formats](https://github.com/ggsegverse/ggseg.formats) is where the atlases and the classes live, and the rest is in the [ggsegverse](https://github.com/ggsegverse) org.

[^ggsegverse]:
    Though we are working on a long-term solution where ggsegverse IS a meta-package like [tidyverse](https://tidyverse.org/) that loads in core packages.

[^namespace]:
    A package's namespace is the private environment holding everything defined in its `R/` files — every function, every internal helper, whether or not you meant anyone else to see them.
    It is what makes `ggseg:::some_internal_thing` work with three colons and `ggseg::geom_brain()` work with two: the namespace holds both, and `NAMESPACE` decides which ones the outside world is allowed to ask for by name.
    Attaching a package with `library()` does not dump this into your session; it puts the exported names on the search path and leaves the rest where they are, which is why two packages can both define a `filter()` without clobbering each other's internals.
    The thing to notice is that `data/` is not part of any of this.
    It is a separate store, loaded lazily, sitting alongside the namespace rather than inside it — which is exactly the gap this post falls into.

[^smell]:
    A code smell is a bit of code that works but reads wrong — the term comes from Kent Beck, popularised by Martin Fowler's [_Refactoring_](https://refactoring.com/) and his [write-up of the idea](https://martinfowler.com/bliki/CodeSmell.html), and the nose metaphor is doing real work.
    A smell is not a bug.
    Bugs announce themselves; you get a wrong answer or an error and you go and fix it.
    A smell is the feeling that something here will cost you later, without yet being able to point at what breaks.
    That is why it is worth asking other people: the whole diagnostic value of a smell is that it is a hunch, and a hunch is exactly the kind of thing you cannot verify by staring harder at your own code.

[^nullary]:
  A function that takes no arguments or parameters.
