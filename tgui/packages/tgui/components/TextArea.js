/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @author Warlockd
 * @license MIT
 */

import { classes } from 'common/react';
import { Component, createRef } from 'react';
import { Box } from './Box';
import { toInputValue } from './Input';
import { KEY_ESCAPE } from 'common/keycodes';

export class TextArea extends Component {
  constructor(props) {
    super(props);
    this.textareaRef = createRef();
    this.fillerRef = createRef();
    this.editing = false;
    const {
      dontUseTabForIndent = false,
    } = props;
    this.handleOnInput = e => {
      const { editing } = this;
      const { onInput } = this.props;
      if (!editing) {
        this.setEditing(true);
      }
      if (onInput) {
        onInput(e, e.target.value);
      }
    };
    this.handleKeyPress = e => {
      const { editing } = this;
      const { onKeyPress } = this.props;
      if (!editing) {
        this.setEditing(true);
      }
      if (onKeyPress) {
        onKeyPress(e, e.target.value);
      }
    };
    this.handleKeyDown = e => {
      const { editing } = this;
      const { onKeyDown } = this.props;
      if (e.keyCode === KEY_ESCAPE) {
        this.setEditing(false);
        e.target.value = toInputValue(this.props.value);
        e.target.blur();
        return;
      }
      if (!editing) {
        this.setEditing(true);
      }
      if (!dontUseTabForIndent) {
        const keyCode = e.keyCode || e.which;
        if (keyCode === 9) {
          e.preventDefault();
          const { value, selectionStart, selectionEnd } = e.target;
          e.target.value = (
            value.substring(0, selectionStart) + "\t"
              + value.substring(selectionEnd)
          );
          e.target.selectionEnd = selectionStart + 1;
        }
      }
      if (onKeyDown) {
        onKeyDown(e, e.target.value);
      }
    };
    this.handleFocus = e => {
      const { editing } = this;
      if (!editing) {
        this.setEditing(true);
      }
    };
    this.handleBlur = e => {
      const { editing } = this;
      const { onChange } = this.props;
      if (editing) {
        this.setEditing(false);
        if (onChange) {
          onChange(e, e.target.value);
        }
      }
    };
  }

  componentDidMount() {
    const nextValue = this.props.value;
    const input = this.textareaRef.current;
    if (input) {
      input.value = toInputValue(nextValue);
    }
  }

  componentDidUpdate(prevProps, prevState) {
    const { editing } = this;
    const prevValue = prevProps.value;
    const nextValue = this.props.value;
    const input = this.textareaRef.current;
    if (input && !editing && prevValue !== nextValue) {
      input.value = toInputValue(nextValue);
    }
  }

  setEditing(editing) {
    // Kept as an instance field rather than state: React batches setState,
    // so handlers running in the same event (e.g. Enter -> blur) would see
    // a stale value. Nothing renders from it.
    this.editing = editing;
  }

  getValue() {
    return this.textareaRef.current && this.textareaRef.current.value;
  }

  render() {
    // Input only props
    const {
      onChange,
      onKeyDown,
      onKeyPress,
      onInput,
      onFocus,
      onBlur,
      onEnter,
      value,
      maxLength,
      placeholder,
      ...boxProps
    } = this.props;
    // Box props
    const {
      className,
      fluid,
      ...rest
    } = boxProps;
    return (
      <Box
        className={classes([
          'TextArea',
          fluid && 'TextArea--fluid',
          className,
        ])}
        {...rest}>
        <textarea
          ref={this.textareaRef}
          className="TextArea__textarea"
          placeholder={placeholder}
          onKeyDown={this.handleKeyDown}
          onKeyPress={this.handleKeyPress}
          onInput={this.handleOnInput}
          onFocus={this.handleFocus}
          onBlur={this.handleBlur}
          maxLength={maxLength} />
      </Box>
    );
  }
}
