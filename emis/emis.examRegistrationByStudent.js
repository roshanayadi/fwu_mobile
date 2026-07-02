$(function () {
    emis.CreateNamespace('examRegistrationByStudent');

    (function (context) {

        context.Title = 'Exam Registration';
        context.ViewModel = {};
        context.ViewModel.Data = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                //vm.InitializeEntry = function ($data) {
                //    context.InitializeEntry($data)
                //}

                vm.SelectAllTheory = function ($data, event) {
                    context.SelectAllTheory($data, event);
                }

                vm.SelectAllPractical = function ($data, event) {
                    context.SelectAllPractical($data, event);
                }

                ko.utils.arrayForEach(vm.SubjectGroups(), function (subjectGroup) {
                    ko.utils.arrayForEach(subjectGroup.SubjectTypes(), function (subjectType) {
                        ko.utils.arrayForEach(subjectType.Subjects(), function (subject) {
                            subject.IsPracticalSelected.subscribe(function (newValue) {
                                setTimeout(function () {
                                    if (vm.IsPracticalPaymentEnabled() && vm.TotalPracticalSelectedCount() > vm.PaidPracticalSubjects()) {
                                        showMessage(context.Title, "Only " + vm.PaidPracticalSubjects() + " subjects can be selected as that is the number you have paid for.", 'warning', function () {

                                        }, 'swal');
                                        subject.IsPracticalSelected(false);
                                    }
                                }, 0);
                            });
                        });
                    });
                });

                vm.TotalPracticalSelectedCount = ko.computed(function () {
                    let totalCount = 0;
                    ko.utils.arrayForEach(vm.SubjectGroups(), function (subjectGroup) {
                        ko.utils.arrayForEach(subjectGroup.SubjectTypes(), function (subjectType) {
                            ko.utils.arrayForEach(subjectType.Subjects(), function (subject) {
                                if (subject.IsPracticalSelected() && subject.HasPractical()) {
                                    totalCount++;
                                }
                            });
                        });
                    });
                    return totalCount;
                });


                vm.Save = function () {
                    context.Save();
                }
                return vm;
            },
        };

        context.SelectAllTheory = function (subjectTypeData, event) {
            var ischecked = $(event.target).is(':checked');
            $(subjectTypeData.Subjects()).each(function (index, item) {
                if (item.HasTheory()) {
                    item.IsTheorySelected(ischecked);
                }
            })
        }

        context.SelectAllPractical = function (subjectTypeData, event) {
            var ischecked = $(event.target).is(':checked');
            $(subjectTypeData.Subjects()).each(function (index, item) {
                if (item.HasPractical()) {
                    item.IsPracticalSelected(ischecked);
                }
            })
        }

        context.InitializeEntry = function ($data) {
            ajaxRequest('/StudentPortal/Application/Initialize', 'POST', { data: { studentAdmissionId: $data.StudentAdmissionId(), examScheduleId: $data.ExamScheduleId() } }, function (response) {
                if (response.IsSuccess) {
                    window.location = '/StudentPortal/Application/Index'
                }
                else {
                    showMessage(context.Title, response.Message, 'error')
                }
            })
        }

        context.Save = function () {

            if (context.ViewModel.IsPracticalPaymentEnabled() && context.ViewModel.TotalPracticalSelectedCount() > context.ViewModel.PaidPracticalSubjects()) {
                showMessage(context.Title, "Only " + context.ViewModel.PaidPracticalSubjects() + " subjects can be selected as that is the number you have paid for.", 'warning', function () {

                }, 'swal');
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel);

            if (context.ViewModel.IsRegular()) {
                let error = false;
                let errorSubjects = [];
                $(model.SubjectGroups).each(function (idx, val) {

                    $(val.SubjectTypes).each(function (idx1, val1) {
                        $(val1.Subjects).each(function (idx2, v) {
                            if (v.HasPractical && v.HasTheory && ((v.IsTheorySelected && !v.IsPracticalSelected) || (!v.IsTheorySelected && v. IsPracticalSelected))) {
                                errorSubjects.push(v.SubjectName);
                                error = true;
                            }
                        })
                    })
                })
                if (error && errorSubjects.length>0) {
                    showMessage(context.Title, "Please select the theory and practical subjects properly of " + errorSubjects.join(", "), 'warning', function () {

                    }, 'swal');
                    return false;
                }
            }

            ajaxRequest('/StudentPortal/Application/Index', 'POST', { data: model }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, "Exam Registration form submitted sucessfully.", 'success', function () {
                        //
                    }, 'swal')
                }
                else {
                    showMessage(context.Title, response.Message, 'error', function () {
                        //
                    }, 'swal')
                    //    showMessage(context.Title, response.Message, 'error')
                }
            })
        }


        context.Initialize = function (model) {
            context.ViewModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel, $("#mainContent")[0]);
        };

    })(emis.examRegistrationByStudent);
});