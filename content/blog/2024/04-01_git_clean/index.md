---
title: Too much git cleaning
author: Dr. Mowinckel
date: '2024-04-01'
image: ''
tags:
  - git
  - fail
slug: "git-clean-woes"
summary: |
  
---
  


I have a type of love-hate relationship with git.
While I love the idea of version control, I often find myself in a situation where I have to clean up my git history.
Maybe I have committed a file that I shouldn't have, or I have made a mistake in my commit message, or I went down a path that just didn't work out.
In these cases, I find myself using `git clean` or `git chechout` quite a bit.
In the worst case, I'll even do a `git reset --hard` to go back to a previous commit.
What all these do, is enable me to go back in time and start over.
`reset` will let you go back in time even after committing, and deciding that the commit is not what you wanted.
The other two help more if you haven't committed yet, but have made changes that you want to get rid of.

I have found that the more I use these commands, the more I get used to them.
But that doesn't mean that I actually do them correctly. 
I have had my fair share of mistakes, where I have lost work that I didn't want to lose.
I had one when preparing my previous post!

I was working on the {neuromat} package, and I had made some changes to the code that just wasn't what i was after.
I decided I wanted to ditch the changes, and go back to what I had before.

`git clean -f`

To my horror... I had forgotten to commit the changes I wanted to keep.
The majority of the good things I had done, went away with the stuff I didn't like. 
I felt... defeated.

I had to start over, and redo the work I had done.
[Maëlle Salmon](https://masalmon.eu/) to the rescue!
I had a chat with her, mostly ranting about how stupid I was, and she suggested I could try to just "undo" in any of my open documents.
In my fury over my git mistakes, I forgot that such a simple solution could exist!

Presto, I could just "undo" myself back to the state I wanted to be in.
Ok, so I did lose somethings that I had done, but they were rather small and easy to fix.

{{< toot user="Patricia" server="social.vivaldi.net" toot="112094753393319808" >}}


