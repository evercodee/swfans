//
//  FFNewViewController.m
//  FZFBase
//
//  Created by fengzifeng on 2017/8/16.
//  Copyright © 2017年 fengzifeng. All rights reserved.
//

#import "FFNewViewController.h"
#import "FFNewListCell.h"
#import "FFPlateDetailViewController.h"
#import "FFPostDetailViewController.h"
#import "FFNewListModel.h"
#import "FFSearchView.h"

@interface FFNewViewController ()

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) FFSearchView *searchView;

@end

@implementation FFNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationBackButtonDefault];
    self.title = @"主题";

    if (_forum_id.length || _searchStr.length) [_tableView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    _tableView.backgroundColor = RGBCOLOR(242, 244, 247);
    self.view.backgroundColor = RGBCOLOR(242, 244, 247);
    [_tableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:_topInset];

    __weak typeof(self) weakSelf = self;
    MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        _page = 0;
        [weakSelf requestData];
    }];
    self.tableView.mj_header = refreshHeader;
    
    MJRefreshBackNormalFooter *footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        _page++;
        [weakSelf requestData];
    }];
    footer.automaticallyHidden = YES;
    self.tableView.mj_footer = footer;
    [self.tableView.mj_header beginRefreshing];


//    [_tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
//    [_tableView addFooterWithTarget:self action:@selector(footerRereshing)];
//    [_tableView headerBeginRefreshing];

    if (!_forum_id.length && !_searchStr.length) {
        FFSearchView *searchView = [FFSearchView showSearchView:^(NSString *text) {
            FFNewViewController *vc = [FFNewViewController viewController];
            vc.searchStr = text;
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }];
        self.searchView = searchView;
    }

}

//-(void)headerRereshing{
//    _page = 0;
//    [self requestData];
//}
//
//- (void)footerRereshing
//{
//    _page++;
//    [self requestData];
//}

- (void)viewWillAppear:(BOOL)animated
{
    [self.searchView addNotice];
    [super viewWillDisappear:animated];
    self.parentViewController.title = @"最新";
    [self.parentViewController setNavigationTitleView:_searchView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.searchView removeNotice];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FFNewListItemModel *model = _dataArray[indexPath.row];
    
    return model.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"FFNewListCell";
    FFNewListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:cellID owner:self options:nil].lastObject;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    FFNewListItemModel *model = _dataArray[indexPath.row];
    [cell updateCell:model];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [((MCViewController *)self.parentViewController).navigationBar endEditing:YES];

    FFPostDetailViewController *vc = [FFPostDetailViewController viewController];
    FFNewListItemModel *model = _dataArray[indexPath.row];
    vc.postId = model.tid;
    
    [self.navigationController pushViewController:vc animated:YES];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    [((MCViewController *)self.parentViewController).navigationBar endEditing:YES];
//}

- (void)requestData
{
    NSUInteger pageIndex = 0;
    NSString *requestUrl;
    if (_forum_id.length) {
        requestUrl = [NSString stringWithFormat:@"%@%@/page/%@/%@",url_threads,_forum_id,@(pageIndex),_type];
    } else if (_searchStr.length) {
        requestUrl = [NSString stringWithFormat:@"%@%@/%@",url_search,@(pageIndex),_searchStr];
        requestUrl = [requestUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        requestUrl = [NSString stringWithFormat:@"%@%@",url_latestthreads,@(pageIndex)];
    }
    
    [[DrHttpManager defaultManager] getRequestToUrl:requestUrl params:nil complete:^(BOOL successed, HttpResponse *response) {
        
        if (successed) {
            FFNewListModel *model = [FFNewListModel objectWithKeyValues:response.payload];
            if (model.data.count) {
                if (!_page) {
                    _dataArray = [model.data mutableCopy];
                } else {
                    [_dataArray addObjectsFromArray:model.data];
                }
                if (!(_forum_id.length && self.isMiss)) {
                    [_tableView reloadData];
                }

            } else {
                if (_page) _page--;
                if (_searchStr.length && !_page) [USSuspensionView showWithMessage:@"搜索无结果"];
            }
        } else {
            if (_searchStr.length) [USSuspensionView showWithMessage:@"搜索无结果"];
        }
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];

    }];
}

//- (void)dealloc
//{
//    _tableView.header = nil;
//    _tableView.footer = nil;
////    [_tableView headerEndRefreshing];
////    [_tableView footerEndRefreshing];
//}

@end
