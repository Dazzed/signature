function getTemplate(template_id, deal_id) {
  $.ajax({
    url: '/document/new?template_id=' + template_id + '&client_deal_id=' + deal_id,
    success: function (data) {
      $('#form-container').html(data);
    },
    error: function (err) {
      console.log('Error in getTemplate');
    }
  })
}

$(function () {
  if (location.pathname.indexOf('deal/show') !== -1) {
    $('#deal-details-tab li:nth-child(2) a').tab('show');
    $("#documents-tab").trigger("click");
  }

  $("#documents-tab").click(function() {
    $.ajax({
      url: '/documents/?client_deal_id=' + $("#documents-tab").data("deal-id"),
      success: function (data) {
        $('#document-container').html(data);
      },
      error: function (err) {
        console.log('Error in fetching documents');
      }
    })
  })
});