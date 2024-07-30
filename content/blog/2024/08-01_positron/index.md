---
title: Positron IDE - A new IDE for data science
author: Dr. Mowinckel
date: '2024-08-01'
categories: []
tags:
  - r
  - data science
  - IDE
  - positron
  - vscode
slug: "positron"
summary: |
  In May I wrote about my favorite IDE's.
  As a result of that post, I was asked to join Posits private beta-testers for their new IDE, Positron.
  Despite being on sick leave, I could not say no, I really wanted to try it out.
  Now Positron is out of private beta, so go on a ride with me as I explore Positron, and see if it can replace my current favorite IDE's.
---

[Positron](https://github.com/posit-dev/positron?tab=readme-ov-file) is a clone of Visual Studio Code (VScode), but with a focus on data science.
I think this was a smart move by Posit's team.
VScode is a great IDE, and it's free, open-source, and cross-platform,
and it has so many developers on board already, and has an extensive library of extensions.
Most of these extensions are also available to Positron, which is a huge advantage!

## Comparison

I'm going to start where I ended the last post, with a comparison of my favorite IDE's, adding Positron to the first column.
Positron has all the features I'm after, and as you can see, it ticks all the boxes just like RStudio and VScode do.
But just like VScode, it has a bit of a learning curve. 


| Feature         | Positron | RStudio | VScode | MATLAB |  vi  | gedit |
|:----------------|:-------:|:-------:|:------:|:------:|:----:|:-----:|
| Script editor   |   ✅    |    ✅    |   ✅   |   ✅   |  ✅  |  ✅   |
| Console         |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Workspace       |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| File browser    |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ✅   |
| Command history |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| View graphics   |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Git integration |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Terminal        |   ✅    |    ✅    |   ✅   |   ✅   |  ✅  |  ❌   |
| Customization   |   ✅    |    ✅    |   ✅   |   ✅   |  ✅  |  ✅   |
| Extensions      |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Linting         |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Code completion |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Debugging       |   ✅    |    ✅    |   ✅   |   ✅   |  ❌  |  ❌   |
| Multi-language  |   ✅    |    ✅    |   ✅   |   ❌   |  ✅  | ✅ |
| Open source     |   ✅    |    ✅    |   ✅   |   ❌   |  ✅  |  ✅   |
| Free            |   ✅    |    ✅    |   ✅   |   ❌   |  ✅  |  ✅   |
| Cross-platform  |   ✅    |    ✅    |   ✅   |   ✅   |  ✅  |  ✅   |
| Learning curve  | Medium |    Low   | Medium |  Low   | High |  Low  |

The learning curve really mostly comes from the way to customise it to work the way _you_ want it to work.
If you are coming from Vscode, and do a lot of data science, Positron is _much better_, in my opinion.
Seeing a proper workspace with variables, plotting and console in one window is a game-changer.

If you are coming from RStudio, you might find it a bit harder to get used to.
That comes mostly from the fact that things need to be customised in Positron, while in RStudio things are more or less set up for you.
This is both good and bad, and kind of depends on what you are after.

I think RStudio is more beginner friendly if you are starting out with R, and want to just get into it.
But, if you are in a multilingual environment, or want to use the same IDE for all your coding, Positron is the way to go.

## Making Positron work for you

Firstly, you might want to have a peak at the [documentation](https://github.com/posit-dev/positron/wiki), which has some excellent information on how to get started.
I'll go through some of the things I've done to make Positron work for me.

### Extensions

With all the possible extensions, you can also make sure it works the way _you_ want it to work.
_Most_ of the extensions for VScode work in Positron, but not all.
It all depends if the developer of the extension also made it available on [Open VSX](https://open-vsx.org/).
I'll go through some of the extensions I'm using.

#### [Raindbow CSV](https://open-vsx.org/extension/mechatroner/rainbow-csv)

This extension is great for viewing CSV files in a more readable way.
This is a must have extensions for anyone who works with CSV files.
It's a great way to quickly see what's in the file, and it's much easier to read than the default CSV viewer.
Each column's content is colored differently, which makes it easier to read.
Very convenient!

![Preview of rainbow csv](rainbow-csv.png)

#### [Prettier - Code formatter](https://open-vsx.org/extension/esbenp/prettier-vscode)

This extension is great for formatting your code.
Of course, it's opinionated and whatnot, but it does help!
This won't help with R or Python, you'll need your own linters for that if you don't like how they work out of the box.
But for JavaScript, TypeScript, HTML, CSS, Yaml, etc., it's great!
While I don't use these languages very often, it's great to have when you need it.

#### [TODO Highlight](https://open-vsx.org/extension/wayou/vscode-todo-highlight)

This extension is great for highlighting TODO and FIXME in your code.
While I don't often add this to my code, I have colleagues that do and it helps me when looking at a project that has this type of setup.

![Todo highligh example](todo.png)

#### [Git Graph](https://open-vsx.org/extension/mhutchie/git-graph)

This extension is great for visualizing your git history.
I don't use it often, but it's great to have when you need it to review what's going on in a project or when you need to you need to backtrace an issue.

![Git graph example](git-graph.png)

#### [Git Actions](https://open-vsx.org/extension/GitHub/vscode-pull-request-github)

This extension is great for working with GitHub Actions. 
I like continuous integration with GitHub Actions very much, 
and this extension makes it easier to see what's going on with your actions.
It helps with syntax highlighting and autocompletion, which is very convenient.
Additionally, you can see the status of your actions in the bottom bar, review the logs and failures, and that makes debugging them so much easier!

#### [GitHub Pull Requests](https://open-vsx.org/extension/GitHub/vscode-pull-request-github)

Another great GitHub integration feature.
This extension makes it easier to work with pull requests.
I always seem to bungle working with PR's locally, and this extension just makes the process so much smoother.



### Command Palette / Keybindings / Keystrokes

The command palette is a great way to find commands, and you can also assign keystrokes to them.
Now, why have I combined all these three things together?
Because, I don't really understand the difference between them and how they are stored.
And when [looking into it](https://github.com/posit-dev/positron/wiki/Keyboard-Shortcuts), I still don't know the difference.
No matter, no matter, I will still the little changes I've made.
That being said, I've only made two changes, and they are both for rendering quarto documents.
I've made the following changes to the `keybindings.json` file:

```json
[
    {
        "key": "ctrl+cmd+k",
        "command": "quarto.renderDocument"
    },
    {
        "key": "shift+cmd+k",
        "command": "-quarto.preview",
        "when": "!quartoRenderScriptActive"
    }
]
```

In this case, I've made a change to the standard keybindings for rending quarto, which also creates a preview of the document.
Now, most people will like this as the default, but given my work with Hugo websites, it's just not for me.
I usually have my hugo server running, and want to see the rendered website, not the rendered stand-alone document.

You can also access the command palette from the botom left corner, where you have the option to edit keystrokes directly.
You can search terms and edit as you like.

![](cmd-palette-1.png)
![](cmd-palette-2.png)

Be aware though!
One of VScode's gotcha's is it's many keybindings.
You will very likely quickly run into issues with overwriting existing keybindings.


### Profiles


