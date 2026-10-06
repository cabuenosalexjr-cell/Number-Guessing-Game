#!/bin/bash

printf 'Enter your username: '
IFS= read -r username

run_sql() {
  psql --username=freecodecamp --dbname=number_guess -X -t --no-align -q -v ON_ERROR_STOP=1 "$@" </dev/null
}

username_sql=$(printf '%s' "$username" | sed "s/'/''/g")
user_id=$(run_sql -c "SELECT user_id FROM users WHERE username = '$username_sql';")
if [[ -z $user_id ]]; then
  user_id=$(run_sql -c "INSERT INTO users (username) VALUES ('$username_sql') RETURNING user_id;")
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
else
  games_played=$(run_sql -c "SELECT COUNT(*) FROM games WHERE user_id = $user_id;")
  best_game=$(run_sql -c "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $user_id;")
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$username" "$games_played" "$best_game"
fi

secret_number=$((RANDOM % 1000 + 1))
guess_count=0

printf 'Guess the secret number between 1 and 1000: '
while IFS= read -r guess; do
  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    printf 'That is not an integer, guess again: '
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_number=$((10#$guess))
  fi
  ((guess_count++))
  if ((guess_number == secret_number)); then
    run_sql -c "INSERT INTO games (user_id, number_of_guesses) VALUES ($user_id, $guess_count);"
    printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$guess_count" "$secret_number"
    break
  elif ((guess_number > secret_number)); then
    printf "It's lower than that, guess again: "
  else
    printf "It's higher than that, guess again: "
  fi
done
