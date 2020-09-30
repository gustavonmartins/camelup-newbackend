FROM elixir:1.10-alpine

RUN apk add --update nodejs npm
COPY . /app
WORKDIR /app/assets
RUN npm install
RUN npm audit fix

WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile
EXPOSE 4000
CMD mix phx.server --no-halt
