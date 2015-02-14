{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE KindSignatures #-}

module ToDoItem where

import Francium
import Francium.HTML
import qualified Francium.HTML as HTML
import Control.Lens ((?=), at)
import Prelude hiding (div, map, span)
import Reactive.Banana
import GHCJS.Foreign
import GHCJS.Types

data Status = Complete | Incomplete
  deriving (Bounded, Enum, Eq, Ord)

negateStatus :: Status -> Status
negateStatus =
  \case
    Incomplete -> Complete
    Complete -> Incomplete

data ToDoItem behavior event =
  ToDoItem {tdiView :: behavior HTML
           ,tdiStatus :: behavior Status
           ,tdiDestroy :: event () }

instance Trim (ToDoItem (Behavior t) (Event t)) where
  type Trimmed (ToDoItem (Behavior t) (Event t)) = ToDoItem (AnyMoment Behavior) (AnyMoment Event)
  type Time (ToDoItem (Behavior t) (Event t)) = t
  trim (ToDoItem a b c) = ToDoItem <$> trimB a <*> trimB b <*> trimE c

data State = Viewing | Editing deriving (Eq)

mkToDoItem :: Frameworks t
           => JSString -> Moment t (ToDoItem (Behavior t) (Event t))
mkToDoItem initialContent =
  do click <- newDOMEvent
     blur <- newDOMEvent
     editInput <- newDOMEvent
     statusCheckboxClicked <- newDOMEvent
     destroy <- newDOMEvent
     let switchToEditing =
           whenE ((Viewing ==) <$> state)
                 (domEvent click)
         state =
           accumB Viewing
                  ((const Editing <$
                    switchToEditing) `union`
                   (const Viewing <$
                    domEvent blur))
         status =
           accumB Incomplete (negateStatus <$ domEvent statusCheckboxClicked)
     pure (ToDoItem (itemRenderer click editInput blur statusCheckboxClicked destroy <$>
                     state <*>
                     stepper initialContent (domEvent editInput) <*>
                     status)
                    status
                    (domEvent destroy))
  where itemRenderer labelClick editInput blur statusCheckboxClicked destroy state inputValue status =
          let items =
                case state of
                  Viewing ->
                    [with label
                          (do case status of
                                Incomplete -> labelStyle
                                Complete -> completeLabelStyle
                              onClick labelClick)
                          [text inputValue]
                    ,with button
                          (do buttonStyle
                              onClick destroy)
                          ["\215"]]
                  Editing ->
                    [with input
                          (do inputStyle
                              value ?= inputValue
                              onBlur blur
                              onInput editInput
                              takesFocus)
                          []]
          in into div
                  (with input
                        (do checkboxStyle
                            onClick statusCheckboxClicked
                            attrs .
                              at "type" ?=
                              "checkbox")
                        [] :
                   items)
        inputStyle =
          attrs .
          at "style" ?=
          "-webkit-font-smoothing: antialiased; box-sizing: border-box; box-shadow: rgba(0, 0, 0, 0.2) 0px -1px 5px 0px inset; border: 1px solid rgb(153, 153, 153); padding: 13px 17px 12px 17px; outline-style: none; line-height: 1.4em; font-size: 24px; width: 506px; margin: 0 0 0 43px; position: relative;"
        checkboxStyle =
          attrs .
          at "style" ?=
          "border-margin: auto 0px; bottom: 0px; top: 0px; position: absolute; height: 40px; width: 40px; text-align: center;"
        labelStyle =
          attrs .
          at "style" ?=
          "-webkit-transition: color 0.4s; transition: color 0.4s; line-height: 1.2; display: block; margin-left: 45px; padding: 15px 60px 15px 15px; word-break: break-word; white-space: pre;"
        completeLabelStyle =
          attrs .
          at "style" ?=
          "-webkit-transition: color 0.4s; transition: color 0.4s; line-height: 1.2; display: block; margin-left: 45px; padding: 15px 60px 15px 15px; word-break: break-word; white-space: pre; color: #d9d9d9; text-decoration: line-through;"
        buttonStyle =
          attrs .
          at "style" ?=
          "-webkit-font-smoothing: antialiased; vertical-align: baseline; font-size: 30px; border-width: 0px; padding: 0px; margin: auto 0px 11px; outline-style: none; -webkit-transition: color 0.2s ease-out initial; transition: color 0.2s ease-out initial; color: rgb(204, 154, 154); height: 40px; width: 40px; bottom: 0px; right: 10px; top: 0px; position: absolute; display: block; background-image: none; background-color: inherit;"