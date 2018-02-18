//
//  TimelinePresenter.swift
//  FavotterView
//
//  Created by hirothings on 2017/12/31.
//  Copyright © 2017年 hirothings. All rights reserved.
//

import Foundation
import RxSwift
import FavotterModel
import TwitterKit

protocol TimelinePresentation: class {
    var view: TimelineView? { get }
    
    init(
        view: TimelineView?,
        router: TimelineWireframe,
        interactor: TimelineUsecase
    )
    
    func viewDidLoad()
    func pullToRefresh()
    func didSelectTweet(with user: User)
    func reachedBottom()
}

protocol TimelineInteractorOutput: class {
    func tweetsFetched(_ tweets: [Tweet])
    func tweetsAdded(_ tweets: [Tweet])
    func tweetsFetchFailed(_ error: Error)
}

class TimelinePresenter: TimelinePresentation {
    var view: TimelineView?
    private let router: TimelineWireframe
    private let interactor: TimelineUsecase
    private let userID: String
    private let store = TWTRTwitter.sharedInstance().sessionStore
    private var tweets: [Tweet] = []
    private var isLoading = false

    required init(
        view: TimelineView?,
        router: TimelineWireframe,
        interactor: TimelineUsecase
        ) {
        self.view = view
        self.router = router
        self.interactor = interactor
        self.userID = store.session()?.userID ?? ""
    }
    
    private let bag = DisposeBag()
    
    func viewDidLoad() {
        fetchTweets(userID)
    }
    
    func pullToRefresh() {
        fetchTweets(userID)
    }
    
    func didSelectTweet(with user: User) {
        router.pushUserProfileView(user)
    }
    
    func reachedBottom() {
        guard let lastID = tweets.last?.id else { return }
        if isLoading { return }
        isLoading = true
        interactor.addTweets(userID: userID, maxID: lastID)
            .subscribe(
                onNext: { [weak self] (tweets: [Tweet]) in
                    self?.tweetsAdded(tweets)
                },
                onError: { [weak self] error in
                    self?.tweetsFetchFailed(error)
                }
            )
            .disposed(by: bag)
    }
    
    private func fetchTweets(_ userID: String) {
        interactor.fetch(with: userID)
            .subscribe(
                onNext: { [weak self] (tweets: [Tweet]) in
                    self?.tweetsFetched(tweets)
                },
                onError: { [weak self] error in
                    self?.tweetsFetchFailed(error)
                }
            )
            .disposed(by: bag)
    }
}

extension TimelinePresenter: TimelineInteractorOutput, ErrorHandler {    
    func tweetsFetched(_ tweets: [Tweet]) {
        isLoading = false
        if tweets.isEmpty {
            view?.showNoContentView()
        } else {
            self.tweets = tweets
            view?.showTimeline(tweets: tweets)
        }
    }
    
    func tweetsAdded(_ tweets: [Tweet]) {
        isLoading = false
        if tweets.isEmpty {
            return
        }
        let prevTweets = self.tweets
        self.tweets += tweets
        let tweetCountDiff = prevTweets.count..<self.tweets.count
        view?.updateTimeline(tweets: self.tweets, tweetsDiff: tweetCountDiff)
    }
    
    func tweetsFetchFailed(_ error: Error) {
        isLoading = false
        let message = handleErrorMessage(error: error)
        view?.showError(message: message)
    }
}
