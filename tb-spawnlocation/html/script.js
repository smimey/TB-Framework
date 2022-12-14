$('document').ready(function() {

    $(".container").hide();
    $("#submit-spawn").hide()

    window.addEventListener('message', function(event) {
        var data = event.data;
        if (data.type === "ui") {
            if (data.status == true) {
                $(".container").fadeIn(250);
            } else {
                $(".container").fadeOut(250);
            }
        }
    })

    $('.location').on('click', function(evt){
        evt.preventDefault(); //dont do default anchor stuff
        var location = $(this).data('location'); //get the text
        var label = $(this).data('label'); //get the text
        $("#spawn-label").html("Locatie bevestigen (" + label +")")
        $("#submit-spawn").attr("data-location", location);
        $("#submit-spawn").fadeIn(100)
        $.post('http://tb-spawnlocation/setCam', JSON.stringify({
            posname: location
        }));
    });

    $('#submit-spawn').on('click', function(evt){
        evt.preventDefault(); //dont do default anchor stuff
        var location = $(this).attr('data-location');
        $(".container").addClass("hideContainer").fadeOut("9000");
        setTimeout(function(){
            $(".hideContainer").removeClass("hideContainer");
        }, 900);
        $.post('http://tb-spawnlocation/spawnplayer', JSON.stringify({
            spawnloc: location
        }));
    });
})
