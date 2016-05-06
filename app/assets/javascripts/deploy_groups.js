// get back a list of deploy groups, generate a select list with 'em
// these are being stored in the DOM to avoid having to make an ajax query etc

var populateProjectSelectList = function() {
  var enviornment = $("#enviorment_permalink").val()
  var groups = JSON.parse($('#deployGroupList').attr('imbededData'))
  // re-initialize the select list
  $('#secret_deploy_group_permalink').empty().append('');
	// Create and append the options that match what
	// we stored in the DOM
  _.each(groups, function(group) {
    if (group[enviornment] != undefined) {
      let value = group[enviornment];
      $('#secret_deploy_group_permalink').append(new Option(value, value));
    }
  })
}
