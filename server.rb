require "sinatra"
require "pg"
require "pry"

set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  @actors = db_connection { |conn| conn.exec("SELECT id, name FROM actors ORDER BY actors.name")}
  erb :'actors/index'
end

get '/actors/:id' do
  thisActor = params[:id].to_i

  @characters = db_connection { |conn| conn.exec(
    "SELECT cast_members.movie_id, cast_members.character, movies.id, movies.title, actors.name FROM cast_members
    JOIN actors ON cast_members.actor_id = actors.id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE cast_members.actor_id = #{thisActor}")}

  erb :'actors/show'
end

get '/movies' do
  if params[:order] == "rating"
    @movies = db_connection { |conn| conn.exec(
      "SELECT movies.id, movies.title, movies.year, movies.rating, studios.name AS studio, genres.name AS genre FROM movies
      JOIN genres ON movies.genre_id = genres.id
      JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.rating ASC")}
  elsif params[:order] == "year"
    @movies = db_connection { |conn| conn.exec(
      "SELECT movies.id, movies.title, movies.year, movies.rating, studios.name AS studio, genres.name AS genre FROM movies
      JOIN genres ON movies.genre_id = genres.id
      JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.year ASC")}
  else
    @movies = db_connection { |conn| conn.exec(
      "SELECT movies.id, movies.title, movies.year, movies.rating, studios.name AS studio, genres.name AS genre FROM movies
      JOIN genres ON movies.genre_id = genres.id
      JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.title")}
  end

  erb :'movies/index'
end

get '/movies/:id' do
  thisMovie = params[:id].to_i

  @movie = db_connection { |conn| conn.exec(
    "SELECT movies.title, movies.year, movies.rating, studios.name AS studio, genres.name AS genre FROM movies
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = #{thisMovie}")}
  @cast = db_connection { |conn| conn.exec("SELECT cast_members.actor_id, cast_members.character, actors.id, actors.name FROM cast_members JOIN actors ON cast_members.actor_id = actors.id WHERE cast_members.movie_id = #{thisMovie}")}

  erb :'movies/show'
end
