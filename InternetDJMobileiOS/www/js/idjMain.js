// InternetDJ Mobile Content Gathering / Display Scripts
//
// Michael Bordash
// michael@internetdj.com
// http://www.internetdj.com

$(document).bind("mobileinit", function(){
  $.mobile.defaultPageTransition = 'slide';
});

$(document).ready(function(){
    $(".pageNavPrev").click(function () {
        var genreName = $('#genreName').text();
        var genreId = $('#genreId').text();
        var total = $('#total').text();
        var page = $('.pageNavPrev').attr("id");
        
        loadGenreArtists(genreId,genreName,total,page);
    });

    $(".pageNavNext").click(function () {
        var genreName = $('#genreArtistsName').text();
        var genreId = $('#genreId').text();
        var total = $('#total').text();
        var page = $('.pageNavNext').attr("id");
        
        loadGenreArtists(genreId,genreName,total,page);
    });
});



function getXidFromNative() {
 
  callXidNativeFunction(
    ["GetXid"] ,
    function(result) {
      alert(result);
    },
 
    function(error) {
      alert("no xid");
    }
  );  
}


function callXidNativeFunction(types, success, fail) {
  return PhoneGap.exec(success, fail, "PushNotification", "printXid", types);
}


function loadSOTD() {
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=sotd&" + new Date().getTime(), function(data){
            var sotdTitle = data[0].song_title + " by " + data[0].artist_name;
            $('#sotdTitle').html(sotdTitle);
            var songId = data[0].song_id;
            $('#sotdPlay').html('<audio controls><source src="http://www.internetdj.com/artists.php?op=stream&song=' + songId + '" preload="auto" /></audio>');
            var sotdImage = data[0].song_image_url;
            $('#sotdItem').html('<img width="200" height="200" src="'+sotdImage+'" />');
    });
}

function loadPopSongList() {
    $('#popSongsList').html('');
    var songListItem = '';
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=top10today&" + new Date().getTime(), function(songs){
       
        $.each(songs, function(i,song) {
            var s_song_title=song.song_title;
            var s_song_id = song.song_id;
            var s_artist_name = song.artist_name;
            var s_song_image = song.song_image_url;
            
            if(s_song_title) {
                songListItem += '<li><a id="' + s_song_id + '" href="#" onClick="javascript:loadSong(\'' + s_song_id + '\');"><img src="' + s_song_image + '" width="120" /><h3>' + s_song_title + '</h3><p>' + s_artist_name + '</p></a></li>';
            }
            
        });
        $('#popSongsList').append(songListItem);
        $('#popSongsList').listview('refresh');
    });
}

function loadGenreList(jsFunc,divUpdate) {
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=genre&" + new Date().getTime(), function(genres){
        $.each(genres, function(i,genre) {
            var s_gen = genre.genre_name;
            var n_gen = null;
            if(genre.parent_genre_id!='0') {
                n_gen = ' &nbsp; ' + genre.genre_name;
            } else {
                n_gen = genre.genre_name;
            }
            
            if(jsFunc == "loadGenreArtists") {
                var countArtists = ' (' + genre.count_artists + ')';
            } else {
                var countArtists = '';
            }
            
            $(divUpdate).append('<li><a id="' + genre.genre_id + '" href="#" onClick="javascript:' + jsFunc + '(\'' + genre.genre_id + '\', \'' + s_gen + '\', \'' + genre.count_artists + '\');">' + n_gen + countArtists + '</a></li>');
        });
        $(divUpdate).listview('refresh');
    });
}

function loadGenreSongs(genreId,genreName) {
    $('#genreSongsList').html('');
    var songListItem = '';
    var cnt = 1;
    $('#genreName').html(genreName);
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=songsbygenre&genre_id=" + genreId + "&" + new Date().getTime(), function(songs){
        $.each(songs, function(i,song) {
            if(cnt<40) {
                var s_song_title=song.song_title;
                var s_song_id = song.song_id;
                var s_artist_name = song.artist_name;
                var s_song_image = song.song_image_url;
                
                if(s_song_title) {
                    songListItem += '<li><a id="' + s_song_id + '" href="#" onClick="javascript:loadSong(\'' + s_song_id + '\');"><img src="' + s_song_image + '" width="120" /><h3>' + s_song_title + '</h3><p>' + s_artist_name + '</p></a></li>';
                }
            } 
            cnt++;
        });
        $('#genreSongsList').append(songListItem);
        $('#genreSongsList').listview('refresh');
    });
    $("#genreSongs").click();
}


function loadGenreArtists(genreId,genreName,total,page) {
    $('#genreArtistsList').html('');
    var artistListItem = '';
    if(page === undefined) {
        page = 0;
    }
    
    $('#genreArtistsName').html(genreName);
    $('#genreId').html(genreId);
    $('#total').html(total);
    $('#pageNav').hide();
    $('.pageNavNext').hide();
    $('.pageNavPrev').hide();


    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=artistsbygenre&genre_id=" + genreId + "&page=" + page + "&now=" + new Date().getTime(), function(artists){
        $.each(artists, function(i,artist) {
      
            var s_artist_name = artist.artist_name;
            var s_artist_id = artist.artist_id;
                
            if(s_artist_name) {
                artistListItem += '<li><a id="' + s_artist_id + '" href="#" onClick="javascript:loadArtist(\'' + s_artist_id + '\',\'' + escape(s_artist_name) + '\');"><h3>' + s_artist_name + '</h3></a></li>';
            }
     
        });
        $('#genreArtistsList').append(artistListItem);
        $('#genreArtistsList').listview('refresh');
    });
    
    var totalPages = (Math.ceil(total/20)) ;
    if( totalPages > 1 ) {
        $('#pageNav').show();
        if( page<(totalPages-1) ) {
            var nextPage = parseInt(page) + 1;
            $('.pageNavNext').removeAttr("id"); 
            $('.pageNavNext').attr("id", nextPage); 
            $('.pageNavNext').show();
        } else {
            $('.pageNavNext').hide();
        }
        
        if( page>=1 )  {
            var prevPage = parseInt(page) - 1;
            $('.pageNavPrev').removeAttr("id"); 
            $('.pageNavPrev').attr("id", prevPage); 
            $('.pageNavPrev').show();
        } else {
            $('.pageNavPrev').hide();
        }
        
    }
    
    $("#genreArtists").click();
}

function loadArtist(artistId,artistName) {                
    $("#artistName").html(unescape(artistName));
    $("#artistSongList").html('');
    var artistSongList = '';
                    
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=songsbyartist&artist_id=" + artistId + "&" + new Date().getTime(), function(songs){
        $.each(songs, function(i,song) {
        
            var songId = song.song_id;
            var songTitle = song.song_title;
            artistSongList += '<li><a id="' + songId + '" href="#" onClick="javascript:loadSong(\'' + songId + '\');"><h3>' + songTitle + '</h3></a></li>';
            
        });
        $("#artistSongList").append(artistSongList);
        $("#artistSongList").listview('refresh');
        

    });
    $("#showArtist").click();
}


function loadSong(songId) {                
    $('#songTitle').html('');
    $('#songArtist').html('');
    $('#songGenre').html('');
    $('#songImage').html('');
    $('#songPlay').html('');
                    
    $.getJSON("http://www.internetdj.com/developers/api.php?api_key=1291928384728192&request_type=song&song_id=" + songId + "&" + new Date().getTime(), function(data){
    
        var songTitle = "<span style='font-weight: bold'>Title:</span> " + data[0].song_title;
//        var songArtist = "<span style='font-weight: bold'>Artist:</span> <a id='" 
//                        + data[0].artist_id 
//                        + "' href='#' onClick='javascript:loadArtist(\"" 
//                        + data[0].artist_id 
//                        + "\",\"" 
//                        + escape(data[0].artist_name) 
//                        + "\");'" 
//                        + data[0].artist_name + " </a>";
        var songArtist = "<span style='font-weight: bold'>Artist:</span> <a id='" + data[0].artist_id + "' href='#' onClick='javascript:loadArtist(\"" + data[0].artist_id + "\",\"" + escape(data[0].artist_name) + "\");'>" + data[0].artist_name + "</a>";
        var songId = data[0].song_id;
        var songImage = data[0].song_image_url;


        $('#songTitle').html(songTitle);
        $('#songArtist').html(songArtist);
        $('#songPlay').html('<audio controls><source src="http://www.internetdj.com/artists.php?op=stream&song=' + songId + '" preload="auto" /></audio>');
        $('#songImage').html('<img width="200" height="200" src="'+songImage+'" />');
    });
    $("#showSong").click();
}
