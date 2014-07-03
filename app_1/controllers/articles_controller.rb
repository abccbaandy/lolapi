require "net/http"
require "net/https"
require "uri"
require "json"

class ArticlesController < ApplicationController
    def new
    end
    def show
        @article = Article.find(params[:id])
    end
    def index
        @articles = Article.all
    end
    def create
        #render plain: params[:article].inspect
        @article = Article.new(article_params)
 
        @article.save
        redirect_to @article
    end
    private
    def article_params
        key = "edadd4f4-b535-4c14-b2f8-b667e4a59e8c"
        #insert 57
        apiRuneID = "http://prod.api.pvp.net/api/lol/static-data/na/v1.2/rune/?locale=en_US&api_key="
        uri = URI.parse("http://prod.api.pvp.net/api/lol/na/v1.4/summoner/20132258/runes?api_key=edadd4f4-b535-4c14-b2f8-b667e4a59e8c")
        src = Net::HTTP.get(uri)
        parsedRunes = JSON.parse(src)
#        params.require(:article).permit(:title, :text)
        params.require(:article).permit(:title, parsedRunes)
    end
end