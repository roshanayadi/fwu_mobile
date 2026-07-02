$(function () {

    $.extend(true, $.fn.modal.Constructor, {
        DEFAULTS: { backdrop: "static", keyboard: false, show: true }
    });
    emis.RoleTypeEnum = {
        SystemAdmin : 1,
        Board : 2,
        College : 3,
        District : 4
    };
});