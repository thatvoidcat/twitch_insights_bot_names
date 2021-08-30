#!/usr/bin/env bash

TEMP_DIR=$(mktemp -d -t "twitchbots_XXXXXX")
LISTS_DIR="lists"

mkdir -p "$LISTS_DIR/base"
mkdir -p "$LISTS_DIR/update"
mkdir -p "ban/$LISTS_DIR/base"
mkdir -p "ban/$LISTS_DIR/update"

function fetch_list {
    # $1: file name to fetch into
    curl "https://api.twitchinsights.net/v1/bots/all" | jq ".bots | .[] | first" | tr -d '"' | sort > "$1"
    #cp allbots "$1"
}

function create_weekly_list {
    t="$LISTS_DIR/base/base_list_$(date +%F).txt"
    fetch_list "$t"
    cat "$t" | awk '{print "/ban " $0}' > "ban/$t"
}

function create_weekly_update_list {
    ol="$LISTS_DIR/base/base_list_$(date --date='1 week ago' +%F).txt"
    nl="$LISTS_DIR/base/base_list_$(date +%F).txt"
    t="$LISTS_DIR/update/weekly_update_$(date +%F).txt"
    if [[ -f "$ol" ]]; then
        comm -13 "$ol" "$nl" > "$t"
        cat "$t" | awk '{print "/ban " $0}' > "ban/$t"
    fi
}

function create_daily_update_list {
    fetch_list "$TEMP_DIR/allbots"
    wd="$(date +%u)"
    wdd=$((wd - 1))
    echo "$wdd"

    comm -13 "$LISTS_DIR/base/base_list_$(date --date="$wdd days ago" +%F).txt" "$TEMP_DIR/allbots" > "$TEMP_DIR/reduced"
    #ls -alh "$TEMP_DIR"
    for (( c=1; c<$wd; c++ ))
    do
        cp "$TEMP_DIR/reduced" "$TEMP_DIR/input"
        if [[ -f "$LISTS_DIR/update/daily_update_$(date --date="$c days ago" +%F).txt" ]]; then
            comm -13 "$LISTS_DIR/update/daily_update_$(date --date="$c days ago" +%F).txt" "$TEMP_DIR/input" > "$TEMP_DIR/reduced"
        fi
    done
    t="$LISTS_DIR/update/daily_update_$(date +%F).txt"
    cp "$TEMP_DIR/reduced" "$t"
    cat "$t" | awk '{print "/ban " $0}' > "ban/$t"
}

if [[ "$(date +%u)" == "1" ]];
then
    # grab new list
    create_weekly_list

    # If last weeks list exists create a weekly diff
    create_weekly_update_list
else
    create_daily_update_list
fi

#echo "$TEMP_DIR"

# Clean up temp dir
rm -rf "$TEMP_DIR"

