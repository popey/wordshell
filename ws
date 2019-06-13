#!/bin/bash
# WordSHell
# Find as many words as you can from the given letters
# For each level there are factors which drive the difficulty


LOGDIR="$HOME/.wordshell/logs"
STATEDIR="$HOME/.wordshell/game"
TMPDIR="$HOME/.wordshell/cache"
LOGFILE="wordshell.log"
LOGGING=false
DOTTING=trueDICTIONARY="/usr/share/dict/words"
#use this to generate the whitelist
#WORDLIST=$DICTIONARY
# Use this for the actual game
WORDLIST="./whitelist"
USEDWORDS="$STATEDIR/usedwords"
LENGTH=6
MIN=3
MAX=$LENGTH
LEVEL=1
MAXLEVEL=100
SCORE=0
message=""

get_date_stamp() {
	local datestamp=$(date +%Y/%m/%d-%H%M%S)
	echo "$datestamp"
}

log() {
    if [ "$LOGGING" == true ]; then
	    DATESTAMP=$(get_date_stamp)
		echo "$DATESTAMP:$1" >> "$LOGDIR/$LOGFILE"
	fi
}

dot() {
    if [ "$DOTTING" == true ]; then
		echo -n .
	fi
}

start_log() {
	if [ ! -d "$LOGDIR" ]; then
	  mkdir -p "$LOGDIR"
	fi
	dot
	log "Start"
}

title_screen() {
	clear
	cat splash.txt
	sleep 1
	clear
}

instructions() {
	clear
	cat instructions.txt
	cat instructions2.txt
	read -r -p '[ENTER]'
}

quit() {
	clear
	cat splash.txt
	echo "Thank's for playing"
	echo ""
	exit
}

menu() {
	local menuloop=true
	while $menuloop; 
	do
		clear
		cat menu.txt
		cat menu2.txt
		read -p "Please select: " menuchoice
		menuchoice=$(echo $menuchoice | tr '[:upper:]' '[:lower:]')
		case $menuchoice in
			i)
			instructions
			;;
			q)
			quit
			;;
			s)
			menuloop=false
			continue 
			;;
		esac
	done
}

get_savestate() {
    log "f:get_savestate"
	if [ ! -f "$STATEDIR"/usedwords ]; then
	  mkdir -p "$STATEDIR"
	  DATESTAMP=$(get_date_stamp)
	  echo "$DATESTAMP" > "$STATEDIR"/usedwords
	  echo $SCORE > "$STATEDIR"/score
	  echo $LEVEL > "$STATEDIR"/level
	else
		SCORE=$(cat "$STATEDIR"/score)
		LEVEL=$(cat "$STATEDIR"/level)
	fi
}

select_a_random_word() {
	log "f:select_a_word"
	local selecting=true
	while $selecting ; do
		# Picking from the max length list for generation
	    theword=$(shuf -n 1 "$TMPDIR/$LENGTH-lw.list")
	    # Picking from the whitelist for real
	    #theword=$(shuf -n 1 "$WORDLIST")
	    # if theword is in USEDWORDS we go around again 
	    grep -q -s $theword "$STATEDIR/usedwords"
	    ret="$?"
	    if [ "$ret" -ne "0" ]; then
	    	selecting=false
	    	log "Selected: $theword"
	    else
	    	selecting=true
	    fi
    done
    #theword="sneers"
    shuftheword=$(echo $theword | sed 's/./&\n/g' | shuf | tr -d "\n" | tr '[:lower:]' '[:upper:]')
    echo "$theword" >> "$STATEDIR/usedwords"
}

select_next_word() {
	log "f:select_a_word"
	foundtheword=false
	local selecting=true
	while read -r w; do
		theword="$w"
	    grep -q -s $theword "$STATEDIR/usedwords"
	    ret="$?"
	    if [ "$ret" -ne "0" ]; then
	    	selecting=false
	    	log "Selected: $theword"
	    	break
	    else
	    	selecting=true
	    fi			
	done < "$WORDLIST"
	if [[ "$selecting" == "true" ]]; then
		log "f:no more words"
		clear
		echo "Fin!"
		exit
	fi
    #theword="sneers"
    shuftheword=$(echo $theword | sed 's/./&\n/g' | shuf | tr -d "\n" | tr '[:lower:]' '[:upper:]')
    echo "$theword" >> "$STATEDIR/usedwords"
}

zero_guesses() {
	> "$STATEDIR"/guesses
}

initialise_level() {
	log "f:initialise_level"
	# Steps to start a new level
	# Find a word we haven't used before, which is appropriate for this level
	#select_a_random_word
	select_next_word
	zero_guesses
	# Find all the anagrams for this word - already done
	# generate_anagrams
	# generate_crossword
}

generate_wordlists () {
	log "f:generate_wordlists"
	if [ ! -d "$TMPDIR" ]; then
	  mkdir -p "$TMPDIR"
	fi
	for i in $(seq $MIN $LENGTH);
	do
		# Check if the wordlist exists, if not, generate it
		if [ ! -f "$TMPDIR"/"$i"-lw.list ]; then
			egrep '^[a-z]{'$i'}$' "$DICTIONARY" > "$TMPDIR"/"$i"-lw.list
		fi
		WORDS=$(wc -l $TMPDIR/$i-lw.list | cut -f1 -d' ' )
		((TOTALWORDS=TOTALWORDS+WORDS))
	done
	log "i:$TOTALWORDS in word lists"
}

generate_crossword() {
	# Temp addition to detect words we should exclude that have
	# no words we can use
	# Maybe we should exclude words that have fewer than a certain number of anagrams
	# And use that to generate a new whitelist
	# No longer needed as we have a whitelist
	# cat "$TMPDIR"/"$theword"-*.list
 #    ret="$?"
 #    if [ "$ret" -ne "0" ]; then
 #    	echo $theword >> "$TMPDIR"/blacklist
 #    	rm "$TMPDIR"/$theword.list
 #    else
 #    	echo $theword >> "$TMPDIR"/whitelist
 #    fi
	#exit
	log "f:generate_crossword"
	# make 5 crosswords, figure out the best one and use that
	for c in $(seq 1 5);
	do
		log "Generate crossword $c"
		# Create temp copy of the word list
		cp $theword.list $STATEDIR/crosswordseed
		# Put longest word in the grid

		# Loop 3 times
			# Look for another word to add
			# slot word into the crossword
			# if the word goes in, 
				# add one to num words
				# remove word from word list
				# add word to wordlist
	done
	# Figure out which of the 5 crosswords was best and use that
	# Throw away all other crosswords
}

generate_anagrams () {
	log "f:generate_anagrams"
	#echo $theword
	blacklist=""
	# Loop through the word lengths from 3 to the length of the chosen word
	for l in $(seq $MIN $MAX);
	do
		dot
		#echo $l
		# Loop through the file of words $i letters in length
		while read -r p; do
  			valid=false
  			# Take a copy of the word
  			processing=$theword
  			log "i:Looking for letters of $p in $processing"
  			# For each letter in $p see if it's in the word
			allfound=0
  			for (( i=0; i<l; i++ )); do
  				pletter=${p:$i:1}
  				log "i:Checking $blacklist for $pletter"
  				if [[ $blacklist = *$pletter* ]]; then
  					log "i:In blacklist, skip this word"
  					((i=l-1))
  					allfound=0
  				else
	  				log "i:Checking if $processing contains $pletter"
	  				if [[ $processing = *$pletter* ]]; then
	  					# it is in the word
	  					log "i:Found $pletter in $processing"
	  					newprocessing=$(echo $processing | sed "s/$pletter//" )
	  					log "i:Removed letter, now $newprocessing"
	  					processing="$newprocessing"
	  					log "i:Add one to $allfound"
	  					((allfound=allfound+1))
	  					# Remove the letter from processing
	  				else
	  					# it is not in the word
	  					log "i:Did not find $pletter in $processing"
	  					allfound=0
	  					# If we're looking for a letter and not found it and we're
	  					# still on the first letter to look for, it should be
	  					# blacklisted
	  					if [[ "$processing" = "$theword" ]]; then 
		  					log "i:Adding $pletter to $blacklist"
		  					blacklist="$pletter $blacklist"
		  				fi
	  					log "i:Skipping rest of the letters"
	  					((i=l-1))
	  				fi
	  			fi
  			done
  			if [[ $allfound == $l ]]; then
  				log "i:Adding $p to $TMPDIR/$theword-$l.list"
  				echo "$p" >> "$TMPDIR/$theword-$l.list"
  			fi
        done <"$TMPDIR/$l-lw.list"
	  #egrep "^[$theword]*$"  "$TMPDIR/$l-lw.list"
	done
    cat "$TMPDIR"/"$theword"-*.list | awk '{ print length(), $0 | "sort -rn" }' | awk -F ' ' '{print $2}' > "$TMPDIR/$theword.list"
}

draw_playarea() {
	# Draw the screen based on the current state
	log "f:draw_playarea"
	clear
	toilet -f term -F metal -F border "WordSHell"
	toilet -f mono12 -F border "$shuftheword"
	## TODO need to add a bit to score to show total words, number found and if main word found
	toilet -f term -F border --gay "Level: $z    Score: $SCORE"
	numtofind=$(wc -l $theword.list | awk -F ' ' '{print $1}')
	((numtofind=numtofind/2))
	numfound=$(wc -l $STATEDIR/guesses| awk -F ' ' '{print $1}')
	toilet -f term -F border --gay "$(echo -n 'Found' $numfound '/' $numtofind': ' && cat $STATEDIR/guesses | tr '\n' ' '|tr '[:lower:]' '[:upper:]')"
	echo "_______________________________________________________________________________"
}

get_input() {
	# here we get a word input from the user
	log get_input
	echo $message
	TIMEBEFOREGUESS=$(date +%s%3N)
    read -p "Guess: " guess
	TIMEAFTERGUESS=$(date +%s%3N)
	((DELTATIME=TIMEAFTERGUESS-TIMEBEFOREGUESS))
	echo $DELTATIME
	((BONUS=10000-$DELTATIME))
	echo $BONUS
}

validate_input() {
	# Did they enter a word that is in the crossword
	# If so, update state
	log "f:validate_input"
	message=""
	if [[ "$guess" == "" ]]; then
		message="Shuffled letters"
   		shuftheword=$(echo $theword | sed 's/./&\n/g' | shuf | tr -d "\n" | tr '[:lower:]' '[:upper:]')
	else
		# Have we already guessed this word
		grep -s -q $guess "$STATEDIR"/guesses
	    ret="$?"
	    if [ "$ret" -eq "0" ]; then
	    	message="Already guessed $(echo guess |tr '[:lower:]' '[:upper:]'), try again!"
	    else
			grep -w -s -q $guess $theword.list
		    ret="$?"
		    if [ "$ret" -eq "0" ]; then
		    	message="$(echo guess |tr '[:lower:]' '[:upper:]') correct!"
		    	echo Calculate score
		    	guesslength=$(echo -n "$guess" | wc -m)
		    	((SCORE=SCORE+guesslength))
		    	if [ "$BONUS" -gt "0" ]; then
		    		((SCORE=SCORE+BONUS))
		    	fi
		    	echo $SCORE > "$STATEDIR"/score
		    	echo $guess >> "$STATEDIR"/guesses
		    	if [[ "$guess" == "$theword" ]]; then
		    		message="$message Well done!"
		    		foundtheword=true
		    	fi
		    else
		    	echo "Not found, try again"
		    fi
		fi
	fi
}

check_end_level() {
	# Have we completed the tasks necessary to finish this level
	log "f:check_end_level"
	if [[ "$guess" == "*skip" ]]; then
		playing=false
		message="Next level! New word!"
	fi
	if [[ "$guess" == "*quit" ]]; then
		quit
	fi
    if [[ "$numfound" > "$numtofind" ]]; then
    	if [[ "$foundtheword" == true ]]; then
    		message="End of level! New word!"
    		playing=false
    	fi
    fi
}

savestate() {
	# Should be called whenever anything changes so we get a clean state
	# to retore from if they kill the game and want to continue later
	log "f:savestate"
}

cleanup () {
	rm -rf "$TMPDIR"
}

clear
start_log
# Obsolete now, may need to migrate to prep app
# generate_wordlists
get_savestate
title_screen
menu
# Main game level incremental loop
for z in $(seq $LEVEL $MAXLEVEL)
do
	log "* Level: $z"
	echo $z > "$STATEDIR"/level
	initialise_level
	playing=true
	while $playing; do
		draw_playarea
		get_input
		validate_input
		check_end_level
	done
done
#cleanup
