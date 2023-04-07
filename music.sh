#!/bin/bash

searchQuery="https://www.youtube.com/results?search_query="
URL="https://www.youtube.com"

declare -A arr

for app in jq mpv; do command -v "${app}" &>/dev/null || not_available+=("${app}"); done
(( ${#not_available[@]} > 0 )) && echo "Please install missing dependencies: ${not_available[*]}" 1>&2 && exit 1

display_results(){
    for (( i = 0; i < $1; i++ ))
    do
        videoResult=$(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].videoRenderer)
        playlistResult=$(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].playlistRenderer)
        if [[ "$videoResult" != null ]]
        then
            echo "$i: $(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].videoRenderer.title.runs[0].text | tr -d '"')"
            id=$(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].videoRenderer.navigationEndpoint.commandMetadata.webCommandMetadata.url | tr -d '"')
            arr[$i]="$id"
            continue
        
        elif [[ "$playlistResult" != null ]]
        then
            echo "$i: [Playlist] $(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].playlistRenderer.title.simpleText | tr -d '"')"
            id=$(echo "$2" | jq .contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[$i].playlistRenderer.viewPlaylistText.runs[0].navigationEndpoint.commandMetadata.webCommandMetadata.url | tr -d '"')
            arr[$i]="$id"
            continue
        fi    
    done

}

get_user_input(){
    read -p "Enter the corresponding number to play the audio: " input
    echo "${arr[$input]}"
}

for var in "$@" 
do
    newUrl=$(echo "$var" | sed -e "s|^|$searchQuery|" -e 's/\s/\+/g')
    ytInitialData=$(curl -s "$newUrl" | grep -P -o 'var ytInitialData = \{.*\};<\/script>')
    json=$(echo "$ytInitialData" | sed -e 's/;<\/script>//' -e 's/var ytInitialData =//')
    result=$(echo "$json" | jq '.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents | length')
    display_results "$result" "$json"
    result=$(get_user_input)
    mpv --no-video --term-playing-msg='Now Playing: ${media-title}' "$URL$result"
    unset arr
done
exit
