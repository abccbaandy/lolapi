require "net/http"
require "net/https"
require "uri"
require "json"



class GuestController < ApplicationController
    def index
    end
    def new
        key = "edadd4f4-b535-4c14-b2f8-b667e4a59e8c"
        #insert 57
        apiRuneID = "http://prod.api.pvp.net/api/lol/static-data/na/v1.2/rune/?locale=en_US&api_key="
        uri = URI.parse("http://prod.api.pvp.net/api/lol/na/v1.4/summoner/20132258/runes?api_key=edadd4f4-b535-4c14-b2f8-b667e4a59e8c")
        src = Net::HTTP.get(uri)
        parsedRunes = JSON.parse(src)
        @runes = Array.new
        for i in 0..29
            tempUri = String.new(apiRuneID)
            tempUri.insert(57, parsedRunes['20132258']['pages'][0]['slots'][i]['runeId'].to_s)
            tempUri << key
            uri = URI.parse(tempUri)
            src = Net::HTTP.get(uri)
            parsed = JSON.parse(src)
            @runes[i] = parsed['description']
        end
    end
    def show
        
        #session[:name] =  params.require(:guest).permit(:name)
        #@name = request.cookies[:name]
        #@name = "444"
    end
    def create
        #@runepage = Lol.new(runepage_params)
 
        #@runepage.save
        #redirect_to @runepage
        #redirect_to 'show.html.erb'
        #@guest = Guest.new(params[:guest][:name])
        #session[:name] =  444
        session[:name] =   params[:guest][:name]
        #render 'show'
        redirect_to '/guest/show'
    end
    private
        def runepage_params
            params.require(:runepage).permit(:name)
        end
end
