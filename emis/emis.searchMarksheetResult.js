$(function () {
    emis.CreateNamespace('searchResult');

    (function (context) {

        context.Title = 'Search Result';
        context.FormId = '#searchResultForm';

        context.ViewModel = {
        };

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.searchResult = function () {
                    context.SearchRecords();
                }
                vm.IsResultAvailable = ko.observable(false);

                return vm;
            }
        };

        context.ResultMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.IsResultAvailable = ko.observable(false);

                return vm;
            }
        };

        //Index Page Related
        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.SearchViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel.SearchViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel.SearchViewModel);
            }
        }

        context.SearchRecords = function () {
            if ($(context.FormId).valid()) {
                var searchModel = ko.mapping.toJS(context.ViewModel.SearchViewModel);
                blockUI();
                ajaxRequest('/Result/Marksheet', 'POST', { data: { model: searchModel } }, function (response) {
                    unblockUI();
                    if (response.IsSuccess && response.Data.StudentName) {
                        if (!ko.dataFor($('#resultContent')[0])) {
                            context.ViewModel.ResultVM = ko.mapping.fromJS(response.Data, context.ResultMapping);
                            ko.applyBindings(context.ViewModel.ResultVM, $('#resultContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data, {}, context.ViewModel.ResultVM);
                        }
                        context.ViewModel.ResultVM.IsResultAvailable(true);
                        $('html, body').animate({
                            scrollTop: 600
                        }, 1000);
                    } else {
                        if (!context.ViewModel.ResultVM) {
                            context.ViewModel.ResultVM = ko.mapping.fromJS({}, context.ResultMapping);
                        }
                        ko.mapping.fromJS(response.Data || {}, {}, context.ViewModel.ResultVM);
                        context.ViewModel.ResultVM.IsResultAvailable(false);
                        showMessage("Error", "Result not found.", 'error');
                    }
                });
            }

        }


    })(emis.searchResult);
});