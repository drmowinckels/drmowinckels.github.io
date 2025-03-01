---
editor_options:
  markdown:
    wrap: sentence
title: 'Setting up Ollama with ellmer, pal and gander as R LLM helpers'
format: hugo-md
author: Dr. Mowinckel
date: '2025-03-01'
categories: []
tags:
  - R
  - Ollama
  - API
  - LLM
slug: ollama
image: images/featured.png
image_alt: ''
summary: ''
seo: ''
---


Large Language Models as code helpers are really one of the biggest changes to programmers daily lives for a good while.
While LLMs can't fix our applications for us, they can help us work a little faster and maybe get a first proof-of-concept out of the door.
Before starting to use Positron, I relied on GitHub co-pilot (I am a registered Educator on GitHub so I have that for free) in both RStudio and VSCode to help me out.
After switching to Positron, I lost that connection as Positron does not have GitHub Co-pilot integration.

Mostly, I was using the GPT run by my University to help me out when I needed it.
But the back and forth between a browser and my IDE was a much less enjoyable experience than having it all in one place.
Especially when I've been working on an update to a work package wrapping an API and needed tests for the new functionality, a GPT is just not as great as a proper co-pilot.

So, as I usually do, I complained to Maêlle, and through the R-Ladies grapevine (meaning Hannah Frick) she told me about [this post](https://www.tidyverse.org/blog/2025/01/experiments-llm) on the Tidyverse blog about R packages to accomplish some functionality I was after.
Knowing [Simon Couch](), I was sure this had to be good.
I had notice him talk about his [pal]() package before, and thought it looked good, and then he adds two more packages [gander]() and [ensure]() to help out during package development and testing.
Genious!

After reading the post, I knew I wanted to give them a go, and finally get my new setup LLM integrated.
But, I am also cheap, I don't want to pay for LLM usage.
I fist had a look at my Unis LLM API, and I think my usage of it would be low enough that I would not be billed.
But that also meant having to figure out and set up an [ellmer]() function to that API, and that was a little more work than I wanted right now.

The next natural step was then to use [Ollama]() which can run locally on your own computer.
Depending on the power of your computer, this is a good option for free LLM aid.
My Mac has 16 cores, so I thought it was worth a try.

## Getting Ollama

First of all, you'll need to [download the Ollama application](https://ollama.com/download), and then install it as your OS requires.
It runs on Mac, Linux and Windows, so people should be more or less covered.
Once installed, you will need to get a model you can run.
Ollama offers many [different models](https://ollama.com/search), so it's mostly about what you want.
To test, I grabbed [deekseek-r1](https://ollama.com/library/deepseek-r1), since DeepSeek is getting all the hype lately, and [ollama3.3](https://ollama.com/library/llama3.3) in case I wanted to test one of Ollama's own models.

``` sh
ollama pull deepseek-r1
ollama llama3.3
```

``` sh
ollama list
```

    NAME                  ID              SIZE      MODIFIED    
    deepseek-r1:latest    0a8c26691023    4.7 GB    5 days ago    
    llama3.1:latest       46e0c10c039e    4.9 GB    5 days ago  

Alrighty, we have some models we can run!
So, we'd better run them.

``` sh
 ollama run deepseek-r1
>>> 
Use Ctrl + d or /bye to exit.
>>> hello
<think>

</think>

Hello! How can I assist you today? 😊

>>> I just wanted to check if this was working. What can you help me with?
<think>
Alright, so the user just said they wanted to check if something was 
working and asked what I can help them with. Looking back at our 
conversation history, I had previously greeted them with a friendly 
"Hello! How can I assist you today?" Now they're following up.

Hmm, maybe they were testing my response or checking if everything is up 
and running smoothly. It's good to acknowledge their follow-up and invite 
them to ask about specific topics. I want to make sure they feel 
comfortable asking whatever they need help with.

I should respond in a friendly manner, letting them know I'm here to 
assist and prompt them to share what they need help with. Keeping the tone 
positive and open-ended encourages them to communicate effectively.
</think>

Great! If you have any questions or need assistance with something, feel 
free to ask. I'm here to help! What can you tell me about what you'd like 
to check or find out? 😊
```

Great.
It's running and responding, and even "thinks" back to me, so I can evaluate if its understood my instructions.
I also asked it to generate a tidyverse-style code for the Gapminder data to plot it.
And it did, the code was indeed somewhat bloated and did not grab the data from the correct source, however the code did work once some small things were adapted.
Good proof of concept, that I could tidy up and work on further if I wanted.

This was running in my terminal, but I wanted it running from within my IDE, Positron.
Let us have a look at how that could look.

## Working with Ellmer

[Ellmer](https://ellmer.tidyverse.org/) is Posits package for interacting with LLM's from within R.
Ellmer already comes with a function to easily communicate with [Ollama as a chat](https://ellmer.tidyverse.org/reference/chat_ollama.html) from within R.

Ellmer uses R6 objects, which I really need to get a little more comfy with.
They feel quite different than "standard" R methods, so it's all a little foreign.
Basically, with R6, you have an object that it self has functions to call on.
On the case of Ellmer, the most essential functionality to chat with the LLM is the `chat()` function.

I'm gonna call my Ollama Chat Ola, which is one of the most common names in Norway.

``` r
ola <- ellmer::chat_ollama(model="deepseek-r1")
ola$chat("Hey. how are you doing?")
```

    <think>

    </think>

    Hi! I'm just a virtual assistant, so I don't have feelings, but I'm 
    here and ready to help you with whatever you need. How are *you* doing
    today? 😊

Cool.
And thanks for reminding me that you don't have feelings, because I am one of those who does indeed thank her LLM's for providing assistance.
(I want my slate clean when the AI uprising happens, maybe they will space me.)

Now we can chat with Ole from within R if we want.
That can be quite convenient.
But we want more :D

## Setting up Pal

-   https://github.com/simonpcouch/pal

## Setting up Ganser

-   https://simonpcouch.github.io/gander

## Setting up Ensure

-   https://simonpcouch.github.io/ensure/

## Setting up R and Positron defaults

-   Positron Keybindings

``` r
options(
  .ensure_fn = "chat_ollama", 
  .ensure_args = list(model = "deepseek-r1:8b")
)

options(
  .gander_chat = ellmer::chat_ollama(model = getOption(".ensure_args")$model)
)
```

## Using the Continue extension

Continue
