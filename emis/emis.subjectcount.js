$(function () {
    emis.CreateNamespace('subjectCount');

    (function (context) {

        context.Title = 'Subject Count';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.Search();
                }
                return vm;
            }
        };
        context.exportTable = function () {
            var elt = document.getElementById('count-table');
            var wb = XLSX.utils.table_to_book(elt, { sheet: "StudentCount" });
            return XLSX.writeFile(wb, 'StudentSubjectCount.xlsx');
        }

        context.Search = function () {
            if ($('#ParentExamScheduleId').val()) {
                ajaxRequest('/Exam/Registration/SubjectCountPartial', 'GET', {
                    data: { parentExamScheduleId: $('#ParentExamScheduleId').val() }
                }, function (response) {
                    $("#subject-area").html(response);
                });
            }
        }


        context.Initialize = function () {
            ajaxRequest('/Exam/Registration/InitializeSubjectCount', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }
                    $(document).on("click", ".btn-export-table", function () {
                        context.exportTable();
                    })

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


    })(emis.subjectCount);
});