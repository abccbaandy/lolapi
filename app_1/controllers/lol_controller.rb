require "net/http"
require "uri"
require "json"



class LolController < ApplicationController
    def getHttp(tempUri)
        #fix chinese or something char bug(not test yet)
        uri = URI.escape(tempUri)
        uri = URI.parse(uri)
       
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        src = http.get(uri.request_uri)
        #src is http/ok or something like that
        if (src.code.to_i!=200)
            parsed = Hash.new
            parsed['errCode'] = src.code
            return parsed
        end
        parsedSrc = JSON.parse(src.body)
        parsed = JSON.parse(parsedSrc.to_json)
        return parsed
    end
    def apiGetSummonerId(name, key)
        tempUri = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/"
        tempUri << name
        tempUri << "?api_key="
        tempUri << key
        parsedSummonerId = getHttp(tempUri)
        if(parsedSummonerId.has_key?('errCode'))
            parsedSummonerId['api'] = "apiGetSummonerId"
            return parsedSummonerId
        end
        return parsedSummonerId
    end
    def apiGetSummonerLeagueEntries(id, key)
        tempUri = "https://na.api.pvp.net/api/lol/na/v2.4/league/by-summoner/"
        tempUri << id
        tempUri << "/entry?api_key="
        tempUri << key
        parsed = getHttp(tempUri)
        if(parsed.has_key?('errCode'))
            parsed['api'] = "apiGetSummonerLeagueEntries"
            return parsed
        end
        return parsed
    end
    def apiGetSummonerRunes(id, key)
        tempUri = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/"
        tempUri << id
        tempUri << "/runes?api_key="
        tempUri << key
        parsedSummonerRunes = getHttp(tempUri)
        return parsedSummonerRunes
    end
    def apiGetSummonerMasteries(id, key)
        tempUri = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/"
        tempUri << id
        tempUri << "/masteries?api_key="
        tempUri << key
        parsedMasteries = getHttp(tempUri)
        return parsedMasteries
    end
    def apiGetStaticDataRune(id, key)
        tempUri = String.new("https://na.api.pvp.net/api/lol/static-data/na/v1.2/rune/")
        tempUri << id
        tempUri << "?api_key="
        tempUri << key
        parsed = getHttp(tempUri)
        #return parsed['description']
        return parsed
    end
    #additional data:ranks
    def apiGetStaticDataMastery(id, key)
        tempUri = String.new("https://na.api.pvp.net/api/lol/static-data/na/v1.2/mastery/")
        tempUri << id
        tempUri << "?masteryData=ranks&api_key="
        tempUri << key
        parsed = getHttp(tempUri)
        #return parsed['description']
        return parsed
    end
    def index
    end
    def show
        key = "edadd4f4-b535-4c14-b2f8-b667e4a59e8c"
        
        session[:guest] = params[:id]
        #summonerId = apiGetSummonerId(session[:guest], key)
        parsedSummonerId = apiGetSummonerId(session[:guest], key)
        if(parsedSummonerId.has_key?('errCode'))
            session[:errCode] = parsedSummonerId['errCode']
            session[:api] = parsedSummonerId['api']
            redirect_to '/lol/'
            return
        end
        summonerId = parsedSummonerId[session[:guest]]['id'].to_s
        
        parsedSummonerLeagueEntries = apiGetSummonerLeagueEntries(summonerId, key)
        if(parsedSummonerLeagueEntries.has_key?('errCode'))
            session[:errCode] = parsedSummonerLeagueEntries['errCode']
            session[:api] = parsedSummonerLeagueEntries['api']
            redirect_to '/lol/'
            return
        end
        
        @summonerDivision = parsedSummonerLeagueEntries[summonerId][0]['entries'][0]['division']
        @summonerTier = parsedSummonerLeagueEntries[summonerId][0]['tier']
        @summonerLeaguePoints = parsedSummonerLeagueEntries[summonerId][0]['entries'][0]['leaguePoints']
        parsedSummonerRunes = apiGetSummonerRunes(summonerId, key)
        
        #find current rune page
        @currentRunePage = -1
        parsedSummonerRunes[summonerId]['pages'].each_with_index do |page, index|
            if(page['current']==true)
                @currentRunePage = index
                break
            end
        end
        
        #show detail of current rune page 
        @runes = Array.new
        @runesColor = Hash.new
        
        if((@currentRunePage != -1) && (!parsedSummonerRunes[summonerId]['pages'][@currentRunePage]['slots'].nil?))
            parsedSummonerRunes[summonerId]['pages'][@currentRunePage]['slots'].each_with_index do |slot, index|
                
                if(Rune.where( :runeId => slot['runeId'].to_s).exists?)
                    runeSql = Rune.where( :runeId => slot['runeId'].to_s).first
                    runeData = Hash.new
                    runeData['description'] = runeSql.runeDescription
                    runeData['rune'] = Hash.new
                    runeData['rune']['type'] = runeSql.runeType
                else
                    runeData = apiGetStaticDataRune(slot['runeId'].to_s, key)
                
                    runeSql = Rune.new( :runeId => runeData['id'], :runeDescription => runeData['description'], :runeType => runeData['rune']['type'] )
                    runeSql.save
                end
                @runes[index] = runeData['description']
                #@runesColor[@runes[index]] = runeData['rune']['type']
                case runeData['rune']['type']
                when "red"
                    @runesColor[@runes[index]] = runeData['rune']['type']
                when "yellow"
                    @runesColor[@runes[index]] = "#B8860B"
                when "blue"
                    @runesColor[@runes[index]] = runeData['rune']['type']
                else
                    @runesColor[@runes[index]] = "#800080"
                end
            end
        end
        
        #sum all same rune
        @runesSum = Hash.new
        @runes.each do |rune|
            if(@runesSum[rune] == nil)
                @runesSum[rune] = 1
            else
                @runesSum[rune] += 1
            end
        end
        
        #find current masteries
        parsedMasteries = apiGetSummonerMasteries(summonerId, key)
        
        @currentMasteryPage = -1
        parsedMasteries[summonerId]['pages'].each_with_index  do |page, index|
            if(page['current']==true)
                @currentMasteryPage = index
                break
            end
        end
        
        #current rank
        @masteries = Hash.new
        #total rank
        @masteriesRank = Hash.new
        @masteriesDescription = Hash.new
        if((@currentMasteryPage != -1) && (!parsedMasteries[summonerId]['pages'][@currentMasteryPage]['masteries'].nil?))
            parsedMasteries[summonerId]['pages'][@currentMasteryPage]['masteries'].each do |mastery|
                @masteries[mastery['id']] = mastery['rank']
            end
        end
        @masteriesNumber = 
        [
            [
                [4111, 4112, 4113, 4114],
                [4121, 4122, 4123, 4124],
                [4131, 4132, 4133, 4134],
                [4141, 4142, 4143, 4144],
                [4151, 4152, 4153, 4154],
                [4161, 4162, 4163, 4164],
            ],
            [
                [4211, 4212, 4213, 4214],
                [4221, 4222, 4223, 4224],
                [4231, 4232, 4233, 4234],
                [4241, 4242, 4243, 4244],
                [4251, 4252, 4253, 4254],
                [4261, 4262, 4263, 4264],
            ],
            [
                [4311, 4312, 4313, 4314],
                [4321, 4322, 4323, 4324],
                [4331, 4332, 4333, 4334],
                [4341, 4342, 4343, 4344],
                [4351, 4352, 4353, 4354],
                [4361, 4362, 4363, 4364],
            ]
        ]
        @masteriesNumberNotExist = [4153, 4161, 4163, 4164, 4223, 4254, 4261, 4263, 4264, 4321, 4351, 4354, 4361, 4363, 4364]
            
        #get all masteriesDescription of masteries
        @masteriesNumber.each do |i|
            i.each do |j|
                j.each do |k|
                    if(!@masteriesNumberNotExist.include?(k))
                        
                        if(Mastery.where( :masteryId => k.to_s).exists?)
                            masterySql = Mastery.where( :masteryId => k.to_s).first
                            parsedMastery = Hash.new
                            parsedMastery['ranks'] = masterySql.masteryRanks
                            parsedMastery['id'] = masterySql.masteryId
                            #.split(",") string(sql) to array
                            parsedMastery['description'] = masterySql.masteryDescription.split(",")
                            parsedMastery['name'] = masterySql.masteryName
                        else
                            parsedMastery = apiGetStaticDataMastery(k.to_s, key)
                            #.join(",") array(json from api) to string
                            masterySql = Mastery.new( :masteryRanks => parsedMastery['ranks'], :masteryId => parsedMastery['id'], :masteryDescription => parsedMastery['description'].join(","), :masteryName => parsedMastery['name'] )
                            masterySql.save
                        end
                        
                        #backup
                        #parsedMastery = apiGetStaticDataMastery(k.to_s, key)
                        
                        if(@masteries.include?(k))
                            @masteriesDescription[k] = parsedMastery['description'][@masteries[k].to_i-1]
                            @masteriesRank[k] = @masteries[k].to_s + "\/" + parsedMastery['ranks'].to_s
                        else
                            @masteriesDescription[k] = parsedMastery['description']
                            @masteriesRank[k] = "0\/" + parsedMastery['ranks'].to_s
                        end
                    end
                end
            end
        end
    end
    def runepage
        key = "edadd4f4-b535-4c14-b2f8-b667e4a59e8c"
        
        #summonerId = apiGetSummonerId(session[:guest], key)
        parsedSummonerId = apiGetSummonerId(session[:guest], key)
        if(parsedSummonerId.has_key?('errCode'))
            session[:errCode] = parsedSummonerId['errCode']
            session[:api] = parsedSummonerId['api']
            redirect_to '/lol/'
            return
        end
        summonerId = parsedSummonerId[session[:guest]]['id'].to_s
        
        parsedSummonerLeagueEntries = apiGetSummonerLeagueEntries(summonerId, key)
        if(parsedSummonerLeagueEntries.has_key?('errCode'))
            session[:errCode] = parsedSummonerLeagueEntries['errCode']
            session[:api] = parsedSummonerLeagueEntries['api']
            redirect_to '/lol/'
            return
        end
        
        @summonerDivision = parsedSummonerLeagueEntries[summonerId][0]['entries'][0]['division']
        @summonerTier = parsedSummonerLeagueEntries[summonerId][0]['tier']
        @summonerLeaguePoints = parsedSummonerLeagueEntries[summonerId][0]['entries'][0]['leaguePoints']
        parsedSummonerRunes = apiGetSummonerRunes(summonerId, key)
        
        #find current rune page
        @currentRunePage = -1
        parsedSummonerRunes[summonerId]['pages'].each_with_index do |page, index|
            if(page['current']==true)
                @currentRunePage = index
                break
            end
        end
        
        #show detail of current rune page 
        @runes = Array.new
        @runesColor = Hash.new
        
        if((@currentRunePage != -1) && (!parsedSummonerRunes[summonerId]['pages'][@currentRunePage]['slots'].nil?))
            parsedSummonerRunes[summonerId]['pages'][@currentRunePage]['slots'].each_with_index do |slot, index|
                
                if(Rune.where( :runeId => slot['runeId'].to_s).exists?)
                    runeSql = Rune.where( :runeId => slot['runeId'].to_s).first
                    runeData = Hash.new
                    runeData['description'] = runeSql.runeDescription
                    runeData['rune'] = Hash.new
                    runeData['rune']['type'] = runeSql.runeType
                else
                    runeData = apiGetStaticDataRune(slot['runeId'].to_s, key)
                
                    runeSql = Rune.new( :runeId => runeData['id'], :runeDescription => runeData['description'], :runeType => runeData['rune']['type'] )
                    runeSql.save
                end
                @runes[index] = runeData['description']
                #@runesColor[@runes[index]] = runeData['rune']['type']
                case runeData['rune']['type']
                when "red"
                    @runesColor[@runes[index]] = runeData['rune']['type']
                when "yellow"
                    @runesColor[@runes[index]] = "#B8860B"
                when "blue"
                    @runesColor[@runes[index]] = runeData['rune']['type']
                else
                    @runesColor[@runes[index]] = "#800080"
                end
            end
        end
        
        #sum all same rune
        @runesSum = Hash.new
        @runes.each do |rune|
            if(@runesSum[rune] == nil)
                @runesSum[rune] = 1
            else
                @runesSum[rune] += 1
            end
        end
        
        #find current masteries
        parsedMasteries = apiGetSummonerMasteries(summonerId, key)
        
        @currentMasteryPage = -1
        parsedMasteries[summonerId]['pages'].each_with_index  do |page, index|
            if(page['current']==true)
                @currentMasteryPage = index
                break
            end
        end
        
        #current rank
        @masteries = Hash.new
        #total rank
        @masteriesRank = Hash.new
        @masteriesDescription = Hash.new
        if((@currentMasteryPage != -1) && (!parsedMasteries[summonerId]['pages'][@currentMasteryPage]['masteries'].nil?))
            parsedMasteries[summonerId]['pages'][@currentMasteryPage]['masteries'].each do |mastery|
                @masteries[mastery['id']] = mastery['rank']
            end
        end
        @masteriesNumber = 
        [
            [
                [4111, 4112, 4113, 4114],
                [4121, 4122, 4123, 4124],
                [4131, 4132, 4133, 4134],
                [4141, 4142, 4143, 4144],
                [4151, 4152, 4153, 4154],
                [4161, 4162, 4163, 4164],
            ],
            [
                [4211, 4212, 4213, 4214],
                [4221, 4222, 4223, 4224],
                [4231, 4232, 4233, 4234],
                [4241, 4242, 4243, 4244],
                [4251, 4252, 4253, 4254],
                [4261, 4262, 4263, 4264],
            ],
            [
                [4311, 4312, 4313, 4314],
                [4321, 4322, 4323, 4324],
                [4331, 4332, 4333, 4334],
                [4341, 4342, 4343, 4344],
                [4351, 4352, 4353, 4354],
                [4361, 4362, 4363, 4364],
            ]
        ]
        @masteriesNumberNotExist = [4153, 4161, 4163, 4164, 4223, 4254, 4261, 4263, 4264, 4321, 4351, 4354, 4361, 4363, 4364]
            
        #get all masteriesDescription of masteries
        @masteriesNumber.each do |i|
            i.each do |j|
                j.each do |k|
                    if(!@masteriesNumberNotExist.include?(k))
                        
                        if(Mastery.where( :masteryId => k.to_s).exists?)
                            masterySql = Mastery.where( :masteryId => k.to_s).first
                            parsedMastery = Hash.new
                            parsedMastery['ranks'] = masterySql.masteryRanks
                            parsedMastery['id'] = masterySql.masteryId
                            #.split(",") string(sql) to array
                            parsedMastery['description'] = masterySql.masteryDescription.split(",")
                            parsedMastery['name'] = masterySql.masteryName
                        else
                            parsedMastery = apiGetStaticDataMastery(k.to_s, key)
                            #.join(",") array(json from api) to string
                            masterySql = Mastery.new( :masteryRanks => parsedMastery['ranks'], :masteryId => parsedMastery['id'], :masteryDescription => parsedMastery['description'].join(","), :masteryName => parsedMastery['name'] )
                            masterySql.save
                        end
                        
                        #backup
                        #parsedMastery = apiGetStaticDataMastery(k.to_s, key)
                        
                        if(@masteries.include?(k))
                            @masteriesDescription[k] = parsedMastery['description'][@masteries[k].to_i-1]
                            @masteriesRank[k] = @masteries[k].to_s + "\/" + parsedMastery['ranks'].to_s
                        else
                            @masteriesDescription[k] = parsedMastery['description']
                            @masteriesRank[k] = "0\/" + parsedMastery['ranks'].to_s
                        end
                    end
                end
            end
        end
    end
    def create
        #@runepage = Lol.new(runepage_params)
 
        #@runepage.save
        #redirect_to @runepage
        session[:guest] = params[:guest][:name].to_s.delete(' ').downcase
        #redirect_to '/lol/runepage'
        redirect_to '/lol/show/'+session[:guest]
    end
end
