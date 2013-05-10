var map_data = {};
var map_values = {};
var map_region_names = {};
var map_rank = {};
var map_data_description = {};
var map_data_loaded = false;
var map_timer;
//Modernizr.smil = false;

$(function() {

    // After three seconds, show a "loading" ticker
    map_timer = setTimeout(function() {
        map_timer = null;
        $("#loading").show();
    }, 3000);

    var loadAsync = function(js_file) {
        (function() {
            var d=document,
            h=d.getElementsByTagName('head')[0],
            s=d.createElement('script');
            s.type='text/javascript';
            s.async=true;
            s.src=js_file;
            h.appendChild(s);
        })();
    };

    loadAsync("data.js");
});

var map;
var map_bounds = [1200, 2000, 5200, 6400];
function mapDataLoaded() {
    if (map_timer) clearTimeout(map_timer);
    $("#loading").hide();
    
    // Create the SVG element to hold the map
    map = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    map.setAttribute("id", "map");
    map.setAttribute("viewBox", map_bounds.join(" "));
    
    var elementId = function(k) {
        return "county-" + k.toLowerCase().replace(/\W+/g, "-");
    };
    
    // Add the counties to the map
    var current_path_by_county_id = {}; // Only used if !Modernizr.smil
    for (var county in map_data._raw) {
        if (!map_data._raw.hasOwnProperty(county)) continue;
        if (county.charAt(0) === "_") continue;
        var path_data = map_data._raw[county];
        if (!path_data) continue;
        
        var e = document.createElementNS("http://www.w3.org/2000/svg", "path");
        e.id = elementId(county);
        map_region_names[e.id] = county;
        e.setAttribute("class", "county");
        e.setAttribute("d", path_data);
        if (!Modernizr.smil) {
            current_path_by_county_id[e.id] = path_data;
        }
        map.appendChild(e);
    }
    
    var maparea = document.getElementById("maparea");
    maparea.insertBefore(map, document.getElementById("loading"));
    maparea.onmousedown = function() { return false; }; // This prevents double-clicks on the map from selecting menu text
    
    // Compute national totals
    map_totals = {};
    for (var x in map_values) {
        map_totals[x] = 0;
        for (var county_key in map_values[x])
            map_totals[x] += map_values[x][county_key];
    }
    
    var dataset;
    var selected_county = null; // Is a county selected?
    var _millions = function(v) {
        if (v >= 1000000) {
            var m = v / 1000000;
            return Math.floor(m) + "." + Math.round(100*(m - Math.floor(m))) + " million";
        }
        return ("" + v).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    };
    var _formatRank = function(rank) {
        if (rank == 1) return "";
        else if (rank == 2) return "second";
        else if (rank == 3) return "third";
        else {
            rank = "" + rank;
            if (rank.match(/1$/)) return rank + "st";
            else if (rank.match(/2$/)) return rank + "nd";
            else if (rank.match(/3$/)) return rank + "rd";
            else return rank + "th";
        }
    };
    var updateInfobox = function() {
        if (!selected_county) return;
        
        // Update the infobox
        var county = map_region_names[selected_county.id];
        if (dataset === "population") {
            var rank = map_rank[dataset][county];
            var value = map_values[dataset][county];
            
            $("#selectedcountypopulation").text(_millions(value));
            $("#selectedcountypopulationrank").text(_formatRank(rank));
        }
        else if (!(dataset in map_values)) {
            //console.log("Dataset not in map_values: " + dataset);
        }
        else {
            var value = map_values[dataset][county] || 0;
            var compared_to_nationally = (value / map_values.population[county]) / (map_totals[dataset] / map_totals.population);
            if (compared_to_nationally >= 1) {
                $("#countycomparison").text(Math.round(100 * (compared_to_nationally - 1)) + "% higher");
            }
            else {
                $("#countycomparison").text(Math.round(100 * (1 - compared_to_nationally)) + "% lower");
            }
            
            $("#countynumber").text(value);
            $("#countycategory").text({
                "all-summer": "Olympian",
                "athletics": "Olympic athlete",
                "swimming": "Olympic swimmer",
                "cycling": "Olympic cyclist",
                "badminton": "Olympic badminton player",
                "gymnastics": "Olympic gymnast",
                "sailing": "Olympic sailor",
                "boxing": "Olympic boxer",
                "hockey": "Olympic hockey player",
                "football": "Olympic footballer",
                "tennis": "Olympic tennis player",
                "basketball": "Olympic basketball player",
                "rugby": "Olympic rugby player",
                "cricket": "Olympic cricketer",
                "tug-of-war": "Olympic tug-of-warrior",
                
                "medals": "Olympic medal",
                "gold-medals": "Olympic gold medal",
                "silver-medals": "Olympic silver medal",
                "bronze-medals": "Olympic bronze medal"
            }[dataset] + (value == 1 ? "" : "s"));
            $("#produced-or-won").text({
                "medals": "won",
                "gold-medals": "won",
                "silver-medals": "won",
                "bronze-medals": "won"
            }[dataset] || "produced");
        }
    };
    
    var timer = null;
    var frames = 48;
    var animation_millis = 2000;
    
    var fakeAnimation = function(data) {
        if (timer != null) {
            clearInterval(timer);
        }
        
        var start_time = new Date().getTime();
        timer = setInterval(function() {
            var elapsed_millis = new Date().getTime() - start_time;
            var x = Math.min(1, elapsed_millis / animation_millis);
            
            if (elapsed_millis >= animation_millis) {
                clearInterval(timer);
                timer = null
            }
            
            for (var k in data) {
                if (!data.hasOwnProperty(k)) continue;
                
                var county_path = document.getElementById(elementId(k));
                var new_path = data[k];
                if (county_path != null) {
                    var county_id = county_path.id;
                    var original_path = current_path_by_county_id[county_id];
                    var original_path_els = original_path.split(" ");
                    var new_path_els = new_path.split(" ");
                    
                    var intermediate_path_els = [];
                    for (var j = 0; j < original_path_els.length; j++) {
                        var a = parseInt(original_path_els[j]), b = parseInt(new_path_els[j]);
                        if (isNaN(a)) {
                            intermediate_path_els[j] = original_path_els[j];
                        }
                        else {
                            intermediate_path_els[j] = Math.round( (1-x) * a + x * b );
                        }
                    }
                    var intermediate_path = intermediate_path_els.join(" ");
                    county_path.setAttribute("d", intermediate_path);
                    current_path_by_county_id[county_id] = intermediate_path;
                }
            }
        }, animation_millis/frames);
    };

    var setDataset = function(new_dataset) {
        dataset = new_dataset;
        if (!(dataset in map_data)) return;
        
        var data = map_data[dataset];

        // Highlight the selected tab
        $(".navitemsselected").removeClass("navitemsselected");
        $("#nav-" + dataset).addClass("navitemsselected");

        // Set the class on the map container
        document.body.className = "map-" + dataset;
        if (selected_county) document.body.className += " a-county-is-selected";

        // Update the explanatory text
        $("#about").html(data._text);
        
        // Show the note, if there is one
        $(".mapnote").hide();
        $("#mapnote-" + dataset).show();

        // Update the rest of the data box, if it’s visible
        updateInfobox();

        // Animate the map to the chosen configuration
        if (Modernizr.smil) {
            var animate_elements = [];
            for (var k in data) {
                if (!data.hasOwnProperty(k)) continue;

                var county_path = document.getElementById(elementId(k));
                var new_path = data[k];
                if (county_path != null) {
                    var animate_element = document.createElementNS("http://www.w3.org/2000/svg", "animate");

                    animate_element.setAttribute("dur", "1s");
                    animate_element.setAttribute("attributeName", "d");
                    animate_element.setAttribute("to", new_path);
                    animate_element.setAttribute("begin", "indefinite");
                    animate_element.setAttribute("fill", "freeze");

                    var existing_animate_elements = $(county_path).find("animate");
                    if (existing_animate_elements.length > 3) {
                        existing_animate_elements.slice(0, 1).remove();
                    }
                    county_path.appendChild(animate_element);
                    animate_elements.push(animate_element);
                }
            }
            for (var i=0; i < animate_elements.length; i++)
                animate_elements[i].beginElement();
            animate_elements = [];
        }
        else {
            // Fake the animation for browsers that don’t support SMIL
            // (I’m looking at you, IE 9)
            fakeAnimation(data);
        }
    };

    var handleHashChange = function() {
        // Which menu item was chosen?
        if (location.hash && location.hash != "#") {
            setDataset(location.hash.substr(1));
        }
        else {
            setDataset("_raw");
        }
    };
    window.addEventListener("hashchange", handleHashChange, false);

    // Check the hash on initial load as well.
    if (location.hash) {
        handleHashChange();
    }
    else {
        //$("#about").html(map_data._raw._text);
    }

    var popup = $("#popup"),
        popup_text = popup.find("#popup-text"),
        popup_visible = false,
        popup_timer = null;
    var hidePopup = function() {
        if (!popup_visible) return;
        popup_visible = false;
        if (popup_timer) { clearTimeout(popup_timer); popup_timer = null; }
        popup_timer = setTimeout(function() {
            if (!popup_visible) popup.fadeOut(100);
            popup_timer = null;
        }, 100);
    };
    var x=0, y=0;
    var showPopup = function(el, x_in, y_in) {
        if (popup_visible) return;
        x = x_in; y = y_in;
        popup_visible = true;
        if (popup_timer) { clearTimeout(popup_timer); popup_timer = null; }
        popup_timer = setTimeout(function() {
            if (popup_visible) {
                popup_text.text(map_region_names[el.id]);
                if (x && y) {
                    popup.css("left", x - popup.outerWidth()/2 + "px")
                         .css("top", y - popup.outerHeight() - 14 + "px");
                }
                popup.show();
            }
            popup_timer = null;
        }, 200);
    };
    $(document.getElementsByClassName("county")).click(function() {
        if (this.id == "county-ireland") return; // Not really a county...
        var already_selected = (this.getAttribute("class") == "county selected-county");
        var something_previously_selected = false;
        $(document.getElementsByClassName("selected-county")).each(function() {
           this.setAttribute("class", "county");
           something_previously_selected = true;
        });
        if (already_selected) {
            $(document.body).removeClass("a-county-is-selected");
            selected_county = null;
        } else {
            this.setAttribute("class", "county selected-county");
            $(".selectedcountyname").text(map_region_names[this.id]);
            if (!something_previously_selected) {
                $(document.body).addClass("a-county-is-selected");
            }
            selected_county = this;
            updateInfobox();
            hidePopup();
        }

        return false;
    }).hover(function(e) {
        if (this.id == "county-ireland") return;
        if (e.shiftKey) return;
        showPopup(this, e.offsetX, e.offsetY);
    }, function() {
        if (this.id == "county-ireland") return;
        hidePopup();
    }).mousemove(function(e) {
        x = e.offsetX;
        y = e.offsetY;
    });
    popup.click(function() {
        hidePopup();
    });
}
