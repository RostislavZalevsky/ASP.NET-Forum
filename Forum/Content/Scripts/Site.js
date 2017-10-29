$(document).ready(function () {     $("#Send").click(function () {         $('input[name="newtext"]').val($("#NewText").html());     });      $("#Save").click(function () {         $('input[name="edittext"]').val($("#EditText").html());     });      $("select.special-flexselect").flexselect({ hideDropdownOnEmptyInput: true });     $("select.flexselect").flexselect();     $("input:text:enabled:first").focus();     //$("form").submit(function () {     //    alert($(this).serialize());     //    return false;     //});      $("#Forums_flexselect").change(function (e) {
        e.preventDefault();
        e.cancelable;
        SetTopic($("#Forums_flexselect").val());
    });      $("#Forums_flexselect").keypress(function (e) {
        if (e.which == 13) {
            SetTopic($("#Forums_flexselect").val());
            $("#TopicForum").submit();
        }     });      function SetTopic(text) {
        $("#topic").val(text);
    } });  