$(function () {
    emis.CreateNamespace('subjectGroup');

    (function (context) {

        context.Title = 'Subject Group';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = {};
                vm.AddNewModel = ko.mapping.fromJS(options.data);


                vm.CurrentSubjectGroupViewModel = ko.mapping.fromJS(options.data);

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.EditClick = function (item) {
                    context.Edit(item.SubjectDetailID());
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                return vm;
            }
        };

        context.CreateMapping = {
            create: function (options) {
                var vm = {};
                vm = ko.mapping.fromJS(options.data);


                vm.CurrentSubjectGroupViewModel = ko.mapping.fromJS(options.data);

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.EditClick = function (item) {
                    context.Edit(item.SubjectDetailID());
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                return vm;
            }
        };

        context.Edit = function (id) {
            ajaxRequest('/Subject/SubjectDetail/Edit/', 'POST', { data: { id: id } }, function (response) {

                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CurrentSubjectDetailVM);
                    $('#subjectDetailModal').modal('show');

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.Save = function () {
            if (!$('#subjectGroupForm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.CurrentSubjectGroupViewModel);
            delete model.__ko_mapping__
            delete model.Programs

            ajaxRequest('/Subject/SubjectGroup/Create', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Subject Group Saved successfully.', 'success', function () {
                            $('#addNewModal').modal('hide');
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ApplyValidation = function () {
            $('#subjectGroupForm').validate({
                rules: {
                    ProgramId: {
                        required: true
                    },
                    SubjectGroupName: {
                        required: true
                    },
                    SubjectGroupShortName: {
                        required: true,
                    }
                },
                messages: {
                    ProgramId: {
                        required: 'Program must be selected'
                    },
                    SubjectGroupName: {
                        required: 'Subject Group Name is required'
                    },
                    SubjectGroupShortName: {
                        required: 'Subject Group Short name is required',
                    }
                }
            });
        }

        context.AddNew = function () {
            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentSubjectGroupViewModel);
            context.ApplyValidation();
            $('#addNewModal').modal('show');
        }

        context.Initialize = function () {
            ajaxRequest('/Subject/SubjectGroup/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#createContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);//subjectDetailModal
                        ko.applyBindings(context.ViewModel, $('#createContent')[0]);//subjectDetailModal

                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.InitializeCreate = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.CreateMapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);//subjectDetailModal

            } else {
                ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
            }

        }



    })(emis.subjectGroup);
});