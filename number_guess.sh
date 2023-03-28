#!/bin/bash
PSQL="psql -U freecodecamp -d number_guess -t -A -c"

SECRET_NUMBER=$(( 1 + $RANDOM % 1000 ))

AUTHENTIFICATION(){
  echo -e "\nEnter your username:"
  read USERNAME
  USERNAME_LENGTH=$(echo -n $USERNAME | wc -m)

  if [[ -z $USERNAME || $USERNAME_LENGTH -gt 22 ]]
  then
    echo -e "\nUsername invalid."
    AUTHENTIFICATION
  else
    USER_ID=$($PSQL "SELECT user_id FROM stats WHERE username = '$USERNAME'")
    if [[ -z $USER_ID ]]
    then
      USER_INSERT=$($PSQL "INSERT INTO stats (username) VALUES ('$USERNAME')")
      USER_ID=$($PSQL "SELECT user_id FROM stats WHERE username = '$USERNAME'")
      echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."

      STATS=$($PSQL "SELECT games_played, best_game FROM stats WHERE user_id = $USER_ID")
      IFS='|' read GAMES_PLAYED BEST_GAME <<< $STATS
      GAME
    else
      STATS=$($PSQL "SELECT games_played, best_game FROM stats WHERE user_id = $USER_ID")
      IFS='|' read GAMES_PLAYED BEST_GAME <<< $STATS

      echo $STATS
      if [[ $GAMES_PLAYED -eq 0 ]]
      then
        echo -e "\nWelcome back, $USERNAME!"
        GAME
      else
        echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
        GAME
      fi
    fi
  fi
}

GAME(){
  if [[ -z $1 ]]
  then
    echo -e "\nGuess the secret number between 1 and 1000:"
    TRIES=0
  else
    echo -e "\n$1"
  fi
  read GUESS

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    GAME "That is not an integer, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    (( ++TRIES ))
    GAME "It's lower than that, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    (( ++TRIES ))
    GAME "It's higher than that, guess again:"
  else
    (( ++TRIES ))
    (( ++GAMES_PLAYED ))
    if [[ $TRIES -lt $BEST_GAME || $BEST_GAME -eq 0 ]]
    then
      BEST_GAME=$TRIES
    fi
    STATS_UPDATE=$($PSQL "UPDATE stats SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID")
    echo -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
  fi
}

AUTHENTIFICATION
