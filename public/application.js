$(document).ready(function(){
  player_hit();
  player_stay();
  dealer_hit();
});

  // Game template: Hit button
  function player_hit() {
  $(document).on('click', '#hit_form input', function(){
    $.ajax({
      type: 'POST',
      url: '/game/hit',
    }).done(function(msg){
      $('#game').replaceWith(msg);
      });
    return false;
    });
  }

  // Game template: Stay button
  function player_stay() {  
  $(document).on('click', '#stay_form input', function(){
    $.ajax({
      type: 'POST',
      url: '/game/stay',
    }).done(function(msg){
      $('#game').replaceWith(msg);
      });
    return false;
    });
  }

  // Game Template: Dealer next move button
  function dealer_hit() {
  $(document).on('click', '#dealer_form input', function(){
    $.ajax({
      type: 'POST',
      url: '/game/hit',
    }).done(function(msg){
      $('#game').replaceWith(msg);
      });
    return false;
    });
  }