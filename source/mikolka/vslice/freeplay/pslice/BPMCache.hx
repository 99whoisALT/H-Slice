package mikolka.vslice.freeplay.pslice;

import backend.Song.SwagSong;
import backend.SongJson;

//? no psych. uses sys
class BPMCache {
    private var bpmMap:Map<String,Int> = [];
    public static var instance = new BPMCache();
    public function new() {
        
    }

    public function getBPM(sngDataPath:String, fileSngName:String):Int {
        if(bpmMap.exists(sngDataPath)){
            //trace("loading from cache");
            return bpmMap[sngDataPath];
        }
        bpmMap[sngDataPath] = 0;
        if(!exists(sngDataPath)){
            #if debug trace('Missing data folder for $fileSngName in $sngDataPath for BPM scrapping!!'); #end //TODO
            return 0;
        }
        var chartFiles = Paths.readDirectory(sngDataPath);
        #if MODS_ALLOWED
        chartFiles = chartFiles.filter(s -> s.toLowerCase().startsWith(fileSngName) && s.endsWith(".json"));
        var chosenChartToScrap = sngDataPath+"/"+chartFiles[0];
        #else
        var regexSongName = fileSngName.replace("(","\\(").replace(")","\\)");
        chartFiles = chartFiles.filter(s -> new EReg('\\/$regexSongName\\/$regexSongName.*\\.json',"").match(s));
        var chosenChartToScrap = chartFiles[0];
        #end
		
		if(exists(chosenChartToScrap)){
            try {
                SongJson.skipChart = true; SongJson.log = false;
                var song:SwagSong = cast SongJson.parse(getContent(chosenChartToScrap));
                SongJson.skipChart = false; SongJson.log = true;

                if(Reflect.hasField(song, 'song')) {
                    song = Reflect.field(song, 'song');
                }

                bpmMap[sngDataPath] = Math.round(song.bpm);

                /* old way
                var bpmFinder = ~/"bpm": *([0-9]+)/g; //TODO fix this regex
                var cleanChart = ~/"notes": *\[.*\]/gs.replace(getContent(chosenChartToScrap),"");
                if(bpmFinder.match(cleanChart)){
                    bpmMap[sngDataPath] = Std.parseInt(bpmFinder.matched(1));
                }*/
            } catch (x) {
			    #if debug else trace('failed to scrap initial BPM for $fileSngName'); #end
            }
		}
		else{
			#if debug trace('Missing chart of $fileSngName in $chosenChartToScrap for BPM scrapping!!'); #end //TODO
			
		}
        return bpmMap[sngDataPath];
    }
    public function clearCache() {
        bpmMap.clear();
    }
    private function exists(path:String) {
        #if MODS_ALLOWED
        return FileSystem.exists(path);
        #else
        @:privateAccess
        for (entry in lime.utils.Assets.libraries.get("default").types.keys()){
            if(entry.startsWith(path)) return true;
        }
        return false;
        #end
    }
    function getContent(path:String) {
        #if MODS_ALLOWED
        return File.getContent(path);
        #else
        return lime.utils.Assets.getText("default:"+path);
        #end
    }
}