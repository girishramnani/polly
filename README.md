# Polly

Polly is a liveview based polling application. It allows the users to

- Create polls with multiple options
- Voting of Polls
- Checking for results of the polls
- Updates the results and vote count in real time


## Demo 
A small demo of showing the vote counts increasing in real-time



https://github.com/girishramnani/polly/assets/6551988/6219da0c-1f7b-443d-9df0-c856e4ff2d3b



## Things to know

- Once you sign in, just click at the username in the upper right corner to log out.

## Architecture

This application from state management standpoint has 2 main components

- `Polly.PollsManager` - This is a module which uses 3 `ets` tables to manage the state of all the polls and their votes. More in-depth explaination is provided below

- `Polly.VoteManager` - Holds the votes casted by a single user. This genserver is instantiated when a user signs
in and is uniquely identified using the user's username. Currently this module is used to check if the user has 
voted for a poll or not but can be extended for audit purposes, listing all votes on a user's profile page and more. More in-depth explaination is provided below

### Polly.PollsManager

PollsManager takes care of all the state related to Polls.
Essentially PollsManager stores data using 3 read and write concurrency enabled ets table.
They are as

  * `:polls` - Stores all the Poll structs with their options, `:id` of the poll is used as a key
    for fast lookup

  * `:polls_votes` - Stores the total votes submitted towards a Poll. This table contains the vote
  counts in the format of `{:id, count}`. update_counter method provided by `:ets` is used to atomically
  increment these votes

  * `:polls_options_votes` - Stores the votes per Option of a Poll. Each Poll can have many options
  and for each option vote count is stored in form of `{:option_id, count`}. Here as `:id` of an option
  is a unique uuid and hence an option can be uniquely identified without knowing the `:id` of the poll.

### Polly.VoteManager

![VoteManager](docs/voteManager.png?raw=true "VoteManager")

VoteManager is a gen-server responsible for holding and managing votes for a user.
A VoteManager process holds votes casted by a single user. Each instance is registered to the VoteRegistry for fast and convinient discovery and is created under a DynamicSupervisor.

This process design works well here because the act of "storing a vote" and checking if a user has "already cast a vote" are independent operation on a user level.

The state of the gen server is of the format `map(poll_id => %Vote{})`. This has been done to provide O(1) lookups.

The `VoteRegistry` used here is also using partitioned storage to allow for more performance.

## Decisions

- I could have definitely considered the `PartitionSupervisor -> DynamicSupervisor -> GenServer` for the `Polls` storage as well but I felt that when multiple users would try to vote on the same poll at the same time I would have had to synchronise those calls using `handle_call` and that could potentially slow down the act of `increasing vote counters`

- Similarly a simpler `VoteManager` backed by an `ets` table similar to `PollyManager` could have definitely worked but I was stuck on one of the criterias of the test i.e. "Action of one user shouldn't block the other".

- Parts of this application may seem a bit over-engineered but I did so keeping in mind that there can be thousands of users using this application at a time.

## TradeOff

- I didn't spend alot of time on the UI and hence its really simple, obviously I would have done a better job if this was production.
- There is a small bug in the `Poll Form` where `add-option` button clears all the data, I didn't have the energy to fix it but I could definitely fix, potentially just store the information on `phx-change` and load it back when a new option is added. But yeah its functional for now.
- I could add alot more tests but felt what I have added cover a good chung of functionality.
- Could have added few more validations.
- Could have added functionalities like edit poll, delete poll, delete option etc but I focused on the core for the test.
- Could have considered using `Horde` based Registry and Supervisor to make this application distributed but that seemed a bit too overkill for this test. But I have production experience with `Horde` and distributed elixir application just to be aware.

## Tests and Credo

I have tried to add as many test as I can, definitely could have added more but felt the ones added were good.
Also added `credo` with a `.credo.exs` (added a few more checks that I personally like). 

- `mix credo` passes
- `mix test --cover` outputs more then `80%` coverage


Output of `mix test --cover`

```

27 tests, 0 failures

Randomized with seed 992261

Generating cover results ...

Percentage | Module
-----------|--------------------------
     0.00% | Polly.Constants
     0.00% | Polly.Schema.Vote
     0.00% | PollyWeb.Layouts
     0.00% | PollyWeb.PageHTML
    50.00% | PollyWeb.ErrorHTML
    63.33% | PollyWeb.UserAuth
    70.73% | PollyWeb.PollLive.Show
    71.43% | PollyWeb.PollLive.FormComponent
    80.00% | Polly.Application
    80.00% | Polly.Schema.Option
    80.00% | Polly.VoteSupervisor
    80.00% | PollyWeb.Telemetry
    81.41% | PollyWeb.CoreComponents
    83.33% | Polly.Factory
    87.50% | Polly.Polls
    90.00% | PollyWeb.Router
    92.86% | Polly.VoteManager
   100.00% | Polly
   100.00% | Polly.Mailer
   100.00% | Polly.PollsManager
   100.00% | Polly.Schema.Poll
   100.00% | PollyWeb
   100.00% | PollyWeb.ConnCase
   100.00% | PollyWeb.Endpoint
   100.00% | PollyWeb.ErrorJSON
   100.00% | PollyWeb.Gettext
   100.00% | PollyWeb.LoginLive.Index
   100.00% | PollyWeb.PollLive.Index
   100.00% | PollyWeb.PollyComponents
   100.00% | PollyWeb.UserSessionController
-----------|--------------------------
    81.52% | Total

```

## How to start

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
