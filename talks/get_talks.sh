repo=drmowinckels/talks

# Fetch the list of folders in the "slides" directory
folders=$(gh api repos/$repo/contents/slides --jq '.[] | select(.type == "dir") | .name' | tac)

# Initialize an empty array to store JSON objects
json_array=()

convert_to_null() {
    if [ -z "$1" ]; then
        echo null
    else
        echo "\"$1\""
    fi
}

# Iterate over each folder
for folder in $folders; do
    echo $folder ----

    # Fetch the content from the index file in the folder
    rmd_content=$(gh api repos/$repo/contents/slides/$folder/index.Rmd --jq '.download_url' 2>/dev/null )
    qmd_content=$(gh api repos/$repo/contents/slides/$folder/index.qmd --jq '.download_url' 2>/dev/null )

    # Check if both files are not found
    if [ -z "$rmd_content" ] && [ -z "$qmd_content" ]; then
        echo "Warning: No index file found for folder $folder"
        continue
    fi

    # Check if the content is not found
    if [[ $(echo "$rmd_content" | jq -r '.message') == "Not Found" ]]; then
        file="$qmd_content"
    else
        file="$rmd_content"
    fi

    file_content=$(curl -sL "$file")

    # Remove leading and trailing quotes and convert empty strings to null
    title=$(convert_to_null "$(echo "$file_content" | grep '^title:' | sed 's/^title: //' | sed 's/^\"//;s/\"$//')")
    subtitle=$(convert_to_null "$(echo "$file_content" | grep '^subtitle:' | sed 's/^subtitle: //' | sed 's/^\"//;s/\"$//')")
    date=\"$(echo $folder | cut -d'-' -f1 | sed 's/\./-/g')\"
    link=$(convert_to_null "$(echo "$file_content" | grep '^link:' | sed 's/^link: //' | sed 's/^\"//;s/\"$//')")

    if [[ $link == null ]]; then
        link=\"https://drmowinckels.io/talks/slides/$folder/\"
    fi

    # Extract tags from YAML front matter
    tags=$(echo "$file_content" | yq e '.tags[]')
    # Check if the string is empty or null
    if [ -z "$tags" ]; then
        tags=null
    else
        # Convert the string to a JSON array
        tags="[$(echo "$tags" | sed 's/"/\\"/g' | awk 'NF { print "\"" $0 "\"" }' | tr '\n' ',' | sed 's/,$//')]"
    fi

    thumbnail=$(convert_to_null "$(echo "$file_content" | grep '^image:' | sed 's/^image: //' | sed 's/^\"//;s/\"$//')")
    if [[ $thumbnail != null ]]; then
        thumbnail=\"https://raw.githubusercontent.com/drmowinckels/talks/main/slides/$folder/$(echo $thumbnail | sed s/\"//g)\"
    fi

    # Construct a JSON object with null values
    json_object="{ 
        \"title\":   $title, 
        \"summary\": $subtitle, 
        \"date\":    $date,
        \"image\":   $thumbnail,
        \"button\":  \"Slides\",
        \"url\":     $link,
        \"tags\":    $tags
    }"
    json_array+=("$json_object")
done

# Convert the array to a JSON array
json_output="[ $(IFS=,; echo "${json_array[*]}") ]"

json_output=$(echo $json_output | jq '.')

# Write the formatted JSON to a file
echo "$json_output" > talks.json