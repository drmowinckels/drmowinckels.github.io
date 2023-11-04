---
title: 'Reorganising Hugo Content and Aliasing'
author: 'Dr. Mowinckel'
date: '2023-11-03'
format: hugo-md
slug: reorganising-hugo
tags:
  - blogdown
  - hugo
  - bash
image: image.png
---

I'm working on a little website revamp, and on that occasion I have been thinking through some reorganisation of the file content of my website.

I'm a stickler for good organisation of content, and I was feeling that my blog folder was turning unruly.
While it was nice machine readable and sorting well etc, it was just not... nice for a human in the long run.
I needed something different, something to soothe my organisatory heart.

What I had was like so:

``` sh
> ls content/blog

2020-04-30-using-freesurfer-annotation-files-to-plot-in-r
2020-05-25-changing-you-blogdown-workflow
2020-06-24-the-linear-regression-family-in-r
2020-12-15-r-package-advent-calendar-2020
2020-12-31-new-year-s-wishes
2021-03-14-new-ggseg-with-geom
2021-03-23-using-github-actions-to-build-your-hugo-website
2021-04-02-external-images-to-heatplots
2021-12-04-adding-giscus-to-your-blogdown-site
2021-12-17-rmarkdown-child-templates
2022-11-07-lets-get-applying
2022-12-01-advent-of-r-functions
2023-09-26-positconf-2023
```

Arguably, a pretty decent way to organise.
ISO dates, sorts nicely, informative names, albeit somewhat long some places.
Like, it ticks a lot of boxes, but its not doing it for me anymore.
I feel like I'm loosing control over the blog folder, and find it hard to look at and navigate all the folders.

So, I want to reorganise them into subfolders by year.
This way, I can more easily distinguish between years and navigate quickly where I need to go, rather than scroll through lots of stuff.
And, its still all very machine searchable.

But, gosh, that would be a lot of work if we didnt script it, which we of course will!
But there are some more things to consider.

## Hugo Aliasing (redirects)

> What if people link to my blogposts, and I break the links?

not good. I need to redirect them to where the content will be, from where it used to be.
Hugo has a nice way of dealing with that, which they call [aliasing](https://gohugo.io/content-management/urls/).
The concept is that, through an array in the front matter of the content markdown, you can specify the urls (on your site) that should redirect people to the specific page.

for example, lets say I move the `2023-09-26-positconf-2023` post, to a `2023/` folder.

``` sh
mv content/blog/2023-09-26-positconf-2023 \  content/blog/2023/09-26-positconf-2023
```

The difference is slight, I just switched a dash for a slash, but it makes for neater organisation.
Now, the new url for this post will be `domain.com/blog/2023/09-26-positconf-2023`, and everyone visiting `domain.com/blog/2023-09-26-positconf-2023` will get a `404 does not exist!`

To fix that, we add a bit in the markdown yaml front matter

    aliases:
      - /blog/2023-09-26-positconf-2023

notice two things: 1. this is an array, 2. it starts with a slash!
That slash cost me [3 hours of debugging](https://fosstodon.org/@Drmowinckels/111348405037507554), don't forget it!

Now, if someone visits `domain.com/blog/2023-09-26-positconf-2023` they will get redirected to the new `domain.com/blog/2023/09-26-positconf-2023`.

In short, we use the old-url as an alias, and Hugo will make sure people coming in from that link get to where the content has been moved automagically.

Neat!

## Fixing the slug

Now, we need to talk about the slug.

No, not slugs, but urls!

<iframe src="https://giphy.com/embed/5pUwbYWSX35GygAKTY" width="480" height="240" frameBorder="0" class="giphy-embed" allowFullScreen>
</iframe>
<p>
<a href="https://giphy.com/gifs/harrypotter-5pUwbYWSX35GygAKTY">via GIPHY</a>
</p>

`/blog/2023/09-26-positconf-2023` is nice as a content naming scheme.
Its organises subfolder by year, and still has the month and say as prefix, to sort nicely.
However, as a url is not awesome.
Most people will not care *when* the post was made, at least not enough to have it in the url, and the url gets sooo looong.

> So, how can we have both worlds?

The second bit of front matter vi want to tamper with is the slug.
The slug is the *exposed* url for the content, so that rather than using the file name (or hugo bundle name in my case) for the post, it uses the slug in stead.

if we define the slug as:

``` yaml
slug: positconf-2023
```

the url the visitor sees is `domain.com/blog/2023/positconf-2023`, which is a much nicer url.
And then I get to both have a nice organisation, and a nice looking url.
win-win!

## Automating the move

Now, I am inherently against doing such tasks manually.
I can script this to make the move better, more consistent, and fast.

I made the script below in bash to take care of all the pesky details for me.
It makes the new subdirectories for year, moves the content there as needed,
adds the yaml front matter for the aliases and slugs, and does it all in seconds.
It did the job perfectly for me, and I am so happy with the result!

### Defining key variables

Let's start slow with a single page to edit.

``` sh
> file=content/blog/2023-09-26-positconf-2023/index.md
> echo $file
content/blog/2023-09-26-positconf-2023/index.md
```

So we have one of the index.md's paths stored in a variable in bash called `file` which we can access by prefixing a `$`.

We can extract the name of the page bundle with a combination of `dirname` (omits the index.md) and `basename` retains the last bit of the path.

``` sh
> folder_title="$(basename $(dirname $file))"
> echo $folder_title
2023-09-26-positconf-2023
```

Since we now have the folder title, and they all follow the pattern: `YYYY-MM-DD-title` we can further extract the year and title from the pattern.
Here, I use the `cut` command with the delimiter argument `-d` with '-' as delimiter character, and select which number after the string has been split to choose with the field `-f` argument and the number in the split.
For the title, I keep everything from the forth field and on, which would omit the date.
For the year, I keep just the first field, which is the year.

``` sh
> # Extract the post title from the filename
> post_title="$(echo $folder_title | cut -d'-' -f4-)"
> echo $post_title
positconf-2023

> # Extract the year from the filename
> year="$(echo ${folder_title} | cut -d'-' -f1)"
> echo $year
2023
```

Now I have the important components, I'll start actually changing things in the blog folder, so its best to start that by defining which folder is the directory we will be working in, and make our first year folder.

``` sh
# Define the source and destination directories
> dir="content/blog"

# Make year folder
> mkdir -p "$dir/$year"
```

We'll need to define the end folder we will get things into, and the wanted file name.

``` sh
# Define the output
> dest_subdir="$dir/$year/$(echo $folder_title | cut -b6-)"
> echo $dest_subdir
content/blog/2023/09-26-positconf-202
```

We have premade the year folder, and we have defined what our new end directory should be.
We should now move the old content to its new path.
One might argue that moving is a daring thing, as it's hard to revert.
But I am working in a git folder so a `git checkout content` will get me back into working order, and moving makes sure that I can see if any content is left behind later.

``` sh
# move contents
mv $(dirname $file/) $dest_subdir
```

With this one simple line, we move the page bundle to its new location in one fell swoop.

### Altering the files and front matter

Now comes the hard part, changing the front matter of the index file.
**Please notice** I am only changing the markdown documents, not the Rmarkdown documents that are the real source of the content.
I have a very good reason to, I don't plan on ever re-knitting the source Rmds from scratch.
Between package changes and R changes, I just don't want to deal with re-knitting my old posts ever again.
So, I leave them alone, and only alter the markdown files, which are the source for what is displayed in the blog.

If you are working with blogdown's default behaviour, which makes the `html` files, this whole approach will need adaptation to work with the Rmds instead, and you'll need to re-knit all your posts...
I don't think I recommend that.
There are ways, but they will be more tricky.

Since we've moved the content, we need to rebuild the path to the index.md based on the new path and the old index.md file name.
At some point in 2021, my posts started having the multilingual `.en` string in their file names.
While my theme supports multilingual posts, I don't use that, so I want to fix that in the same go, I'll show that at the end.

``` sh
> file_new=$(echo $dest_subdir/$(basename $file))
> echo $file_new
content/blog/2023/09-26-positconf-2023/index.md
```

To edit the front matter alone, we need to do some magic.
Since I'm sticking to bash, this is gonna get ugly!

We will focus in using `sed` which is a string replacement CLI for bash.
First, we will extract the front matter.

``` sh
> sed -n '/^---$/,/^---$/p' "$file_new"
---
title: Posit::conf 2023
author: Dr. Mowinckel
date: '2023-09-26'
tags:
  - R
image: speak.jpeg
---
```

Look at that!
`sed` is very powerful, and it can do so many things.
Don't think I knew about this amazing capability, I've only ever used it for string replacement before, this was with a little bit of help from copilot.
I need to save that temporarily, so I can acutally work with it, so we put it in a temporary file, by redirecting the console output to a file using `>`.

``` sh
# Save the existing front matter to a temporary file
sed -n '/^---$/,/^---$/p' "$file_new"  > "$dest_subdir/tmp"
```

Next, if I want to *add* parameters to the front matter, I'll need to remove the last `---` to do so.
This bit of `sed` with the `$ d` (yes there is a space between!) will remove the last line of a file, and we redirect that into a new file.

``` sh
# remove last ---
sed '$ d' "$dest_subdir/tmp" > "$dest_subdir/tmp3"
```

And then, the file might already have a slug defined in the front matter, so we need to remove that to replace with the new one we want.

``` sh
# remove existing slug
sed '/^slug:/d' "$dest_subdir/tmp3" > "$dest_subdir/tmp2"
```

This is sed string replacement as I know it.
Its in the format of `/pattern/replacement`, and in this case the "replacement being `d` means delete in this specific case.
It uses regex, so the also define that the line needs to start with (`^`) `slug:` so we don't replace anything else in the file that might mention"slug".

Last thing to add to the front matter is the new alias.
I know that none of my posts have any aliases defined already.
If yours does, you'll need to deal with them before you can do this.

Aliases beed to be in an array, and arrays in yaml can either be comma separated between `[]` or on separate lines starting with `-`.
I prefer the latter, its much neater in my opinion.

``` sh
# Add an alias to the front matter of the old file
echo 'aliases:' >> "$dest_subdir/tmp2"
echo "  - '/"$(dirname $file | cut -d'/' -f 2-6)"'" >> "$dest_subdir/tmp2"
```

A couple of things to notice!
First, notice two `echo`s, because we want sepaerate lines.
and second, we are using `>>` rather than just `>`.
In bash that means "append to file", rather than "write to file".
The difference being that append adds lines at the bottom of the file, and write means "overwrite", deleting the old content.

Lastly, we want to end the front matter with the standard tripple dash `---`.

``` sh
# add trailing --- to end yaml section
echo '---' >> "$dest_subdir/tmp2"
```

Our front matter is done!
But... we need to get the rest of the content in!

In comes another piece of sed magic. Just like we could only grasb the front matter before, we can now grab everything that is **not** the front matter!

``` sh
# add content
sed -n '/^---$/,/^---$/!p' "$file_new" >> "$dest_subdir/tmp2"
```

and we append that straight to the temporary file that has the new front matter :)

Our file is now ready, and we should do some cleaning before we do the final piece, and make it into the new index.md.

We need to delete the temp files we no longer need (but not tmp2!), and also delete the old index file.
Remember how I said that I from 2021 had an issue with some being added the language code?
Well, deleting the original file, to then rename tmp2 just index.md fixed all that easily.
So, that's what we'll do!

``` sh
# remove temp files
rm "$dest_subdir/tmp" "$dest_subdir/tmp3" "$dest_subdir/$(basename $file)"

# Move the modified front matter to the new file
mv "$dest_subdir/tmp2" "$dest_subdir/index.md"
```

Now, no matter if the originating file is `index.en.md` or not, I will have a file name as I wish. Clean!

And that is it!

Now that I had it confirmed that this worked for a single file, I deleted what I had changed in the blog folder, ran a `git checkout content` to restore file folder to its original state, and created the entire script, and called it `rename_files.sh`, which I placed in the root of my project.

``` sh
#!/bin/bash

# Define the source and destination directories
dir="content/blog"

# Loop through the source directory
for file in ${dir}/*/index*.md; do
  echo "$file ---------------------"

  # folder title
  folder_title="$(basename $(dirname $file))"

  # Extract the post title from the filename
  post_title="$(echo $folder_title | cut -d'-' -f4-)"

  # Extract the year from the filename
  year="$(echo ${folder_title} | cut -d'-' -f1)"
  mkdir -p "$dir/$year"

  # Define the output
  dest_subdir="$dir/$year/$(echo $folder_title | cut -b6-)"

  # move contents
  mv $(dirname $file/) $dest_subdir

  file_new=$(echo $dest_subdir/$(basename $file))

  # Save the existing front matter to a temporary file
  sed -n '/^---$/,/^---$/p' "$file_new"  > "$dest_subdir/tmp"

  # remove last ---
  sed '$ d' "$dest_subdir/tmp" > "$dest_subdir/tmp3"

  # remove existing slug
  sed '/^slug:/d' "$dest_subdir/tmp3" > "$dest_subdir/tmp2"

  # Add a slug parameter to the front matter
  echo 'slug: "'"$post_title"'"' >> "$dest_subdir/tmp2"

  # Add an alias to the front matter of the old file
  echo 'aliases:' >> "$dest_subdir/tmp2"
  echo "  - '/"$(dirname $file | cut -d'/' -f 2-6)"'" >> "$dest_subdir/tmp2"

  # add trailing --- to end yaml section
  echo '---' >> "$dest_subdir/tmp2"

  # add content
  sed -n '/^---$/,/^---$/!p' "$file_new" >> "$dest_subdir/tmp2"

  # remove temp files
  rm "$dest_subdir/tmp" "$dest_subdir/tmp3" "$dest_subdir/$(basename $file)"
  
  # Move the modified front matter to the new file
  mv "$dest_subdir/tmp2" "$dest_subdir/index.md"
done

echo "Content reorganization completed."
```

Now, I could run it in my terminal with

``` sh
sh rename_files.sh
```

and watch the magic happen!

### Word of caution

Don't run this willy-nilly.
Make sure it makes sense for a single one of your files first, then give it a go.
For one, this will *not* work for a multilingual site, it would need quite some work to do that.

But I am all-in-all very happy with my new setup, and feel its a good first step towards a new and improved website!

![](image.png)
