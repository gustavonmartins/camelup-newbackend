FROM elixir:1.10.4-alpine
COPY . /app
WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.compile
CMD iex -S mix phx.server