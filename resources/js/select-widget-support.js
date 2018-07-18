        /**
         * update the select menu with id `wid` from this `data` whose fields include
         * this `entity_key` and these `fields`
         */
        function updateMenuOptions(wid, entity_key, fields, data){
          $('#' + wid).children().filter(function(){
            return $(this).attr('selected') === undefined;
          }).remove().end();

          $.each(data, function(key, entry){
            $('#' + wid).append(
              $('<option></option>').attr('value', key).text(entry));
          });
        }
